require 'rails_helper'

RSpec.describe 'Create Mix', type: :system do
  let!(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'user with no favorite playlists' do
    it 'shows the empty favorites state with a link to manage playlists' do
      visit create_mix_path

      expect(page).to have_content("Create a Mix")
      expect(page).to have_content("You don't have any favorite playlists yet")
      expect(page).to have_link('Manage Playlists', href: favorite_playlists_path)
    end
  end

  describe 'user with favorite playlists' do
    let!(:tracked_playlist) { create(:tracked_playlist, name: 'Morning Run') }
    let!(:snapshot) do
      create(:playlist_snapshot,
        tracked_playlist: tracked_playlist,
        playlist_id:      tracked_playlist.playlist_id,
        playlist_items:   { 'video1' => { 'title' => 'Track 1', 'description' => '' } }
      )
    end
    let!(:favorite) { create(:favorite_playlist, user: user, tracked_playlist: tracked_playlist) }

    it 'shows the user\'s favorite playlists as selectable options' do
      visit create_mix_path

      expect(page).to have_content('Morning Run')
      expect(page).to have_css("input[type=checkbox]")
    end

    it 'navigates to the player when a playlist is selected and mix is created' do
      visit create_mix_path

      check 'selected_playlist_ids[]', allow_label_click: false
      click_button 'Create Mix'

      expect(page).to have_current_path(/player/)
      expect(page).to have_content('Player')
    end

    it 'shows the selected playlist name on the player page' do
      visit create_mix_path
      check 'selected_playlist_ids[]', allow_label_click: false
      click_button 'Create Mix'

      expect(page).to have_content('Morning Run')
    end
  end

  describe 'discover playlists section' do
    let!(:other_playlist) { create(:tracked_playlist, name: 'Community Playlist') }
    let!(:snapshot) do
      create(:playlist_snapshot, tracked_playlist: other_playlist, playlist_id: other_playlist.playlist_id)
    end

    it 'shows playlists not in the user\'s favorites under Discover New' do
      visit create_mix_path

      expect(page).to have_content('Discover New')
      expect(page).to have_content('Community Playlist')
    end
  end
end
