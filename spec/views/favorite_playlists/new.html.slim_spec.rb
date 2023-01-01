require 'rails_helper'

RSpec.describe "favorite_playlists/new", type: :view do
  before(:each) do
    assign(:favorite_playlist, FavoritePlaylist.new(
      user: nil,
      tracked_playlist: nil
    ))
  end

  it "renders new favorite_playlist form" do
    render

    assert_select "form[action=?][method=?]", favorite_playlists_path, "post" do

      assert_select "input[name=?]", "favorite_playlist[user_id]"

      assert_select "input[name=?]", "favorite_playlist[tracked_playlist_id]"
    end
  end
end
