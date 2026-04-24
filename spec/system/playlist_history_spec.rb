require 'rails_helper'

RSpec.describe 'Playlist History', type: :system do
  let!(:user) { create(:user) }
  let!(:tracked_playlist) { create(:tracked_playlist, name: 'Study Sessions') }
  let!(:snapshot) do
    create(:playlist_snapshot,
      tracked_playlist: tracked_playlist,
      playlist_id:      tracked_playlist.playlist_id,
      playlist_items:   { 'vid1' => { 'title' => 'Focus Track' } }
    )
  end
  let!(:favorite) { create(:favorite_playlist, user: user, tracked_playlist: tracked_playlist) }

  before { login_as(user, scope: :user) }

  describe 'navigating from Manage Playlists to playlist history' do
    it 'follows the View History link to the correct history page' do
      visit favorite_playlists_path

      click_link 'View History'

      expect(page).to have_current_path(playlist_history_path(tracked_playlist.playlist_id))
      expect(page).to have_content("History for #{tracked_playlist.name}")
    end
  end

  describe 'viewing history for a playlist with changes' do
    let!(:delta) do
      create(:playlist_delta,
        tracked_playlist:  tracked_playlist,
        playlist_snapshot: snapshot,
        added:             [{ 'title' => 'New Arrival', 'url' => 'https://youtube.com/watch?v=abc' }],
        removed:           [{ 'title' => 'Removed Song', 'url' => 'https://youtube.com/watch?v=xyz' }]
      )
    end

    it 'shows added songs in the history' do
      visit playlist_history_path(tracked_playlist.playlist_id)

      expect(page).to have_content('New Arrival')
    end

    it 'shows removed songs in the history' do
      visit playlist_history_path(tracked_playlist.playlist_id)

      expect(page).to have_content('Removed Song')
    end

    it 'shows the change date' do
      visit playlist_history_path(tracked_playlist.playlist_id)

      expect(page).to have_content(snapshot.created_at.strftime('%b %d, %Y'))
    end
  end

  describe 'viewing history for a playlist with no changes yet' do
    it 'renders the history page without errors' do
      visit playlist_history_path(tracked_playlist.playlist_id)

      expect(page).to have_content("History for #{tracked_playlist.name}")
    end
  end
end
