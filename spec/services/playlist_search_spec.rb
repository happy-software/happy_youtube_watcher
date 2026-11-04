require 'rails_helper'

RSpec.describe PlaylistSearch do
  let!(:eighties) { create(:tracked_playlist, name: 'Sausboi - Eighties Bangers') }
  let!(:chill)    { create(:tracked_playlist, name: 'Sausboi - Chill Mix') }

  before do
    create(:playlist_snapshot, tracked_playlist: eighties, playlist_items: playlist_items(
      'older'    => { title: 'George Michael - Older (Official Video)', channel: 'georgemichaelVEVO', description: "I should have known\nIt seemed too easy" },
      'take_on'  => { title: 'a-ha - Take On Me', channel: 'a-ha', description: 'Remastered in 4K' },
    ))
    create(:playlist_snapshot, tracked_playlist: chill, playlist_items: playlist_items(
      'older'    => { title: 'George Michael - Older (Official Video)', channel: 'georgemichaelVEVO' },
      'weightless' => { title: 'Weightless', channel: 'Marconi Union', description: 'Ambient piece made with sound therapists' },
    ))
  end

  def search(query, playlists = TrackedPlaylist.all)
    described_class.call(query, tracked_playlists: playlists)
  end

  def video_ids(query, playlists = TrackedPlaylist.all)
    search(query, playlists).videos.map(&:video_id)
  end

  it 'matches video titles' do
    expect(video_ids('take on me')).to eq(['take_on'])
  end

  it 'matches titles with a typo' do
    expect(video_ids('wieghtless')).to include('weightless')
  end

  it 'matches a misspelled word inside a longer title' do
    expect(video_ids('micheal')).to eq(['older'])
  end

  it 'matches when every word is misspelled' do
    expect(video_ids('goerge micheal')).to eq(['older'])
  end

  it 'ranks the exact phrase in a description above a loose title match' do
    create(:playlist_snapshot, tracked_playlist: chill, playlist_items: playlist_items(
      'loose'  => { title: 'Coming Out of the Monkey Head' },
      'lyrics' => { title: 'Older', description: "You're out of time, I'm letting go" },
    ))

    expect(video_ids('out of time')).to eq(['lyrics', 'loose'])
  end

  it 'does not fuzzy match descriptions' do
    expect(video_ids('therapist')).to eq(['weightless'])
    expect(video_ids('therapizts')).to be_empty
  end

  it 'matches channel names' do
    expect(video_ids('marconi')).to eq(['weightless'])
  end

  it 'matches descriptions' do
    expect(video_ids('sound therapists')).to eq(['weightless'])
  end

  it 'matches when the words are in different fields and a different order' do
    expect(video_ids('older vevo')).to eq(['older'])
  end

  it 'matches a video id' do
    expect(video_ids('take_on')).to eq(['take_on'])
  end

  it 'ranks title matches above description matches' do
    create(:playlist_snapshot, tracked_playlist: chill, playlist_items: playlist_items(
      'mentions' => { title: 'Something else', description: 'Better than Weightless' },
      'weightless' => { title: 'Weightless', channel: 'Marconi Union' },
    ))

    expect(video_ids('weightless')).to eq(['weightless', 'mentions'])
  end

  it 'groups a video that is in several playlists into one result' do
    result = search('george michael').videos

    expect(result.map(&:video_id)).to eq(['older'])
    expect(result.first.tracked_playlists).to contain_exactly(eighties, chill)
  end

  it 'matches playlist names' do
    expect(search('chil mix').playlists).to eq([chill])
  end

  it 'only searches the playlists it is given' do
    expect(video_ids('a-ha', TrackedPlaylist.where(id: chill.id))).to be_empty
    expect(search('eighties', TrackedPlaylist.where(id: chill.id)).playlists).to be_empty
  end

  it 'returns nothing for a query that is too short' do
    result = search(' a ')

    expect(result.playlists).to be_empty
    expect(result.videos).to be_empty
  end

  it 'treats LIKE wildcards in the query as plain text' do
    expect(video_ids('%%')).to be_empty
  end
end
