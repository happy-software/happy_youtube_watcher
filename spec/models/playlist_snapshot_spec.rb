require 'rails_helper'

RSpec.describe PlaylistSnapshot do
  let(:song_data) do
    {
      'title'                  => 'song_1_title',
      'complete'               => true,
      'position'               => 1,
      'channelId'              => 'owner_channel_id',
      'playlistId'             => 'playlist_id',
      'resourceId'             => { 'kind' => 'youtube#video', 'videoId' => 'song_1' },
      'thumbnails'             => {},
      'description'            => 'some description',
      'publishedAt'            => '2019-01-03T21:58:39Z',
      'channelTitle'           => 'channelTitle',
      'videoOwnerChannelId'    => 'channelid',
      'videoOwnerChannelTitle' => 'channelname',
    }
  end

  describe '.capture_all_tracked_playlists!' do
    subject { described_class.capture_all_tracked_playlists! }

    before do
      TrackedPlaylist.all.each(&:destroy)
      TrackedPlaylist.create(playlist_id: 'playlist_id', name: 'channelname')
      PlaylistSnapshot.create(playlist_id: 'playlist_id', playlist_items: {}, etag: etag1)
      allow(described_class).to receive(:get_playlist_items_from_yt).and_return(mocked_yt_response)
      allow(PlaylistDifferenceRenderer).to receive(:post_diff)
      allow(ArchiveWorker).to receive(:archive_videos)
      allow(ENV).to receive(:fetch).with("YT_API_KEY").and_return("fake_api_key_in_test")
      allow(Youtube::PlaylistEtagFetcher).to receive(:new).with('playlist_id').and_return(etag_fetcher_double)
    end

    let(:etag_fetcher_double) { double(fetch: etag2) }
    let(:etag1) { 'etag1' }
    let(:etag2) { 'etag2' }

    let(:mocked_yt_response) do
      { 'song_1' => song_data }
    end

    it 'takes a snapshot' do
      expect { subject }.to change { PlaylistSnapshot.count }.by(1)
    end

    it 'posts diff to slack' do
      expect(PlaylistDifferenceRenderer).to receive(:post_diff)
      subject
    end

    it 'creates a PlaylistDelta with the added songs' do
      expect { subject }.to change { PlaylistDelta.count }.by(1)
    end

    it 'calls ArchiveWorker to archive new videos' do
      expect(ArchiveWorker).to receive(:archive_videos)
      subject
    end

    context "when the etag hasn't changed" do
      let(:etag1) { 'same_etag' }
      let(:etag2) { 'same_etag' }

      it "does not create a new snapshot" do
        expect { subject }.to_not change { PlaylistSnapshot.count }
      end

      it "does not post diff to slack" do
        expect(PlaylistDifferenceRenderer).not_to receive(:post_diff)
        subject
      end
    end

    context 'when the playlist content has no changes despite different etag' do
      before do
        PlaylistSnapshot.create(
          playlist_id:    'playlist_id',
          playlist_items: mocked_yt_response,
          etag:           etag1
        )
        allow(described_class).to receive(:get_playlist_items_from_yt).and_return(mocked_yt_response)
      end

      it 'does not create a new snapshot' do
        expect { subject }.not_to change { PlaylistSnapshot.count }
      end
    end

    context 'when the tracked playlist is inactive' do
      before do
        TrackedPlaylist.find_by(playlist_id: 'playlist_id').update!(active: false)
      end

      it 'skips the inactive playlist' do
        expect { subject }.not_to change { PlaylistSnapshot.count }
      end

      it 'does not call the YouTube API' do
        expect(described_class).not_to receive(:get_playlist_items_from_yt)
        subject
      end
    end

    context 'when YouTube returns a request error' do
      before do
        allow(described_class).to receive(:get_playlist_items_from_yt)
          .and_raise(Yt::Errors::RequestError)
      end

      it 'deactivates the playlist' do
        subject
        expect(TrackedPlaylist.find_by(playlist_id: 'playlist_id').active).to be false
      end

      it 'posts an error alert to Slack' do
        expect(YoutubeWatcher::Slacker).to receive(:post_message)
          .with(anything, '#happy-alerts')
        subject
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '.get_working_songs' do
    it 'returns songs that are not broken' do
      songs = {
        'video1' => { 'title' => 'Normal Song' },
        'video2' => { 'title' => 'Another Song' },
      }
      expect(described_class.get_working_songs(songs)).to eq(songs)
    end

    it 'filters out deleted videos' do
      songs = {
        'video1' => { 'title' => 'Normal Song' },
        'video2' => { 'title' => 'Deleted video' },
      }
      expect(described_class.get_working_songs(songs).keys).to eq(['video1'])
    end

    it 'filters out private videos' do
      songs = {
        'video1' => { 'title' => 'Private video' },
        'video2' => { 'title' => 'Normal Song' },
      }
      expect(described_class.get_working_songs(songs).keys).to eq(['video2'])
    end

    it 'returns an empty hash when all songs are broken' do
      songs = {
        'video1' => { 'title' => 'Deleted video' },
        'video2' => { 'title' => 'Private video' },
      }
      expect(described_class.get_working_songs(songs)).to be_empty
    end

    it 'returns an empty hash when given an empty hash' do
      expect(described_class.get_working_songs({})).to eq({})
    end
  end

  describe '#shuffled_working_songs' do
    let(:tracked_playlist) { create(:tracked_playlist) }
    let(:snapshot) do
      create(:playlist_snapshot, tracked_playlist: tracked_playlist, playlist_id: tracked_playlist.playlist_id, playlist_items: {
        'video1' => song_data.merge('title' => 'Song One', 'videoOwnerChannelTitle' => 'Owner'),
        'video2' => song_data.merge('title' => 'Private video'),
      })
    end

    it 'returns working songs in the expected format' do
      result = snapshot.shuffled_working_songs
      titles = result.map { |s| s[:title] }
      expect(titles).to include('Song One')
      expect(titles).not_to include('Private video')
    end

    it 'includes the correct keys in each song' do
      result = snapshot.shuffled_working_songs
      expect(result.first.keys).to match_array([:title, :video_id, :playlist_id, :description, :playlist_owner])
    end

    it 'includes the playlist_id on each song' do
      result = snapshot.shuffled_working_songs
      expect(result.first[:playlist_id]).to eq(tracked_playlist.playlist_id)
    end
  end

  describe '.shuffle_playlists' do
    let(:tp1) { create(:tracked_playlist) }
    let(:tp2) { create(:tracked_playlist) }

    before do
      create(:playlist_snapshot, tracked_playlist: tp1, playlist_id: tp1.playlist_id, playlist_items: {
        'vid1' => song_data.merge('title' => 'Song from playlist 1', 'videoOwnerChannelTitle' => 'Owner 1'),
      })
      create(:playlist_snapshot, tracked_playlist: tp2, playlist_id: tp2.playlist_id, playlist_items: {
        'vid2' => song_data.merge('title' => 'Song from playlist 2', 'videoOwnerChannelTitle' => 'Owner 2'),
      })
    end

    it 'returns songs from all specified playlists' do
      result = described_class.shuffle_playlists([tp1.playlist_id, tp2.playlist_id])
      titles = result.map { |s| s[:title] }
      expect(titles).to include('Song from playlist 1', 'Song from playlist 2')
    end

    it 'returns an empty array when no playlist ids are given' do
      expect(described_class.shuffle_playlists([])).to eq([])
    end

    it 'silently skips playlist ids that have no snapshots' do
      expect { described_class.shuffle_playlists(['nonexistent_id']) }.not_to raise_error
    end
  end
end
