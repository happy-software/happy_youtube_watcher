require 'rails_helper'

RSpec.describe PlaylistSnapshot do
  describe '.capture_all_tracked_playlists!' do
    subject { described_class.capture_all_tracked_playlists! }

    before do
      TrackedPlaylist.all.each(&:destroy)
      TrackedPlaylist.create(playlist_id: 'playlist_id', name: 'channelname')
      PlaylistSnapshot.create(playlist_id: 'playlist_id', playlist_items: {}, etag: etag1)
      allow(described_class).to receive(:get_playlist_items_from_yt).and_return(mocked_yt_response)
      allow(PlaylistDifferenceRenderer).to receive(:post_diff)
      allow(ArchiveWorker).to receive(:archive_videos) # don't kick off async workers in test
      allow(ENV).to receive(:fetch).with("YT_API_KEY").and_return("fake_api_key_in_test")
      allow(Youtube::PlaylistEtagFetcher).to receive(:new).with('playlist_id').and_return(etag_fetcher_double)
    end

    let(:etag_fetcher_double) do
      double(fetch: etag2)
    end
    let(:etag1) { 'etag1' }
    let(:etag2) { 'etag2' }

    let(:mocked_yt_response) do
      {
        'song_1' => {'title'=>'song_1_title',
                     'complete'=>true,
                     'position'=>259,
                     'channelId'=>'playlist_owner_channel_id',
                     'playlistId'=>'playlist_id',
                     'resourceId'=>{'kind'=>'youtube#video', 'videoId'=>'song_1'},
                     'thumbnails'=> {},
                     'description'=>'some description string',
                     'publishedAt'=>'2019-01-03T21:58:39Z',
                     'channelTitle'=>'channelTitle',
                     'videoOwnerChannelId'=>'channelid',
                     'videoOwnerChannelTitle'=>'channelname'}
      }
    end

    it 'takes a snapshot' do
      expect { subject }.to change { PlaylistSnapshot.count }.by(1)
    end

    it 'posts diff to slack' do
      expect(PlaylistDifferenceRenderer).to receive(:post_diff)
      subject
    end

    context "when the etag hasn't changed" do
      let(:etag1) { 'same_etag' }
      let(:etag2) { 'same_etag' }

      it "should not create a new snapshot" do
        expect { subject }.to_not change { PlaylistSnapshot.count }
      end
    end
  end
end
