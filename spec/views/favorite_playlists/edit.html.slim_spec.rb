require 'rails_helper'

RSpec.describe "favorite_playlists/edit", type: :view do
  let(:favorite_playlist) {
    FavoritePlaylist.create!(
      user: nil,
      tracked_playlist: nil
    )
  }

  before(:each) do
    assign(:favorite_playlist, favorite_playlist)
  end

  it "renders the edit favorite_playlist form" do
    render

    assert_select "form[action=?][method=?]", favorite_playlist_path(favorite_playlist), "post" do

      assert_select "input[name=?]", "favorite_playlist[user_id]"

      assert_select "input[name=?]", "favorite_playlist[tracked_playlist_id]"
    end
  end
end
