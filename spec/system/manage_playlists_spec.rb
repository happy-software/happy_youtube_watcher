require 'rails_helper'

RSpec.describe 'Manage Playlists', type: :system do
  let!(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'first-time user with no favorite playlists' do
    it 'shows the empty state message' do
      visit favorite_playlists_path

      expect(page).to have_content('Favorite Playlists')
      expect(page).to have_content('No favorite playlists yet')
      expect(page).to have_content('Add Playlist')
    end

    it 'redirects unauthenticated users to sign in' do
      Warden.test_reset!
      visit favorite_playlists_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe 'adding a favorite playlist' do
    let!(:tracked_playlist) { create(:tracked_playlist, name: 'My Chill Mix') }
    let!(:snapshot) do
      create(:playlist_snapshot, tracked_playlist: tracked_playlist, playlist_id: tracked_playlist.playlist_id)
    end

    before do
      allow(TrackPlaylist).to receive(:call).and_return(tracked_playlist)
    end

    it 'adds the playlist and shows it on the manage page' do
      visit favorite_playlists_path

      fill_in 'Paste YouTube Playlist URL', with: "https://www.youtube.com/playlist?list=#{tracked_playlist.playlist_id}"
      click_button 'Add Playlist'

      expect(page).to have_content('New playlist favorited!')
      expect(page).to have_content('My Chill Mix')
    end
  end

  describe 'with existing favorite playlists' do
    let!(:tracked_playlist) { create(:tracked_playlist, name: 'Weekend Vibes') }
    let!(:snapshot) do
      create(:playlist_snapshot, tracked_playlist: tracked_playlist, playlist_id: tracked_playlist.playlist_id)
    end
    let!(:favorite) { create(:favorite_playlist, user: user, tracked_playlist: tracked_playlist) }

    it 'lists the favorite playlists with their names' do
      visit favorite_playlists_path

      expect(page).to have_content('Weekend Vibes')
    end

    it 'shows actions for each playlist' do
      visit favorite_playlists_path

      expect(page).to have_link('Open')
      expect(page).to have_link('View History')
      expect(page).to have_button('Remove')
    end

    it 'removes a playlist when the Remove button is clicked' do
      visit favorite_playlists_path
      click_button 'Remove'

      expect(page).to have_content('was successfully deleted')
      expect(page).not_to have_css('.playlist-card')
    end
  end
end
