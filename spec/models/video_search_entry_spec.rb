require 'rails_helper'

RSpec.describe VideoSearchEntry do
  let(:tracked_playlist) { create(:tracked_playlist) }

  def snapshot_with(videos)
    create(:playlist_snapshot, tracked_playlist: tracked_playlist, playlist_items: playlist_items(videos))
  end

  it 'indexes the videos when a snapshot is created' do
    snapshot_with('vid1' => { title: 'Older', channel: 'georgemichaelVEVO', description: 'Official video' })

    expect(tracked_playlist.video_search_entries.sole).to have_attributes(
      video_id:      'vid1',
      title:         'Older',
      channel_title: 'georgemichaelVEVO',
      description:   'Official video',
      thumbnail_url: 'https://i.ytimg.com/vi/vid1/mqdefault.jpg',
      position:      0,
    )
  end

  it 'replaces the previous entries when a newer snapshot is created' do
    snapshot_with('vid1' => { title: 'Old song' })
    snapshot_with('vid2' => { title: 'New song' })

    expect(tracked_playlist.video_search_entries.pluck(:video_id)).to eq(['vid2'])
  end

  it 'leaves other playlists alone' do
    other = create(:tracked_playlist)
    create(:playlist_snapshot, tracked_playlist: other, playlist_items: playlist_items('other' => { title: 'Other' }))

    snapshot_with('vid1' => { title: 'Mine' })

    expect(other.video_search_entries.pluck(:video_id)).to eq(['other'])
  end

  it 'skips videos that are unavailable' do
    snapshot_with(
      'ok'       => { title: 'Working' },
      'deleted'  => { title: 'Deleted video' },
      'private'  => { title: 'Private video' },
      'blocked'  => { title: 'Region blocked', extra: { Youtube::VideoAvailabilityChecker::REASON_KEY => 'blocked' } },
    )

    expect(tracked_playlist.video_search_entries.pluck(:video_id)).to eq(['ok'])
  end

  describe '.rebuild_from' do
    it 'rebuilds from the newest snapshot of every playlist' do
      snapshot_with('vid1' => { title: 'Old song' })
      newest = snapshot_with('vid2' => { title: 'New song' })
      described_class.delete_all

      described_class.rebuild_from(PlaylistSnapshot.newest_per_playlist)

      expect(PlaylistSnapshot.newest_per_playlist).to contain_exactly(newest)
      expect(described_class.pluck(:video_id)).to eq(['vid2'])
    end
  end
end
