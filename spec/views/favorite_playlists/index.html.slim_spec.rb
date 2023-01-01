require 'rails_helper'

RSpec.describe "favorite_playlists/index", type: :view do
  before(:each) do
    assign(:favorite_playlists, [
      FavoritePlaylist.create!(
        user: nil,
        tracked_playlist: nil
      ),
      FavoritePlaylist.create!(
        user: nil,
        tracked_playlist: nil
      )
    ])
  end

  it "renders a list of favorite_playlists" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
