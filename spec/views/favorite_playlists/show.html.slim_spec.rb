require 'rails_helper'

RSpec.describe "favorite_playlists/show", type: :view do
  before(:each) do
    assign(:favorite_playlist, FavoritePlaylist.create!(
      user: nil,
      tracked_playlist: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
