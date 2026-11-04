require 'rails_helper'

RSpec.describe "Search", type: :request do
  let(:user) { create(:user) }

  let!(:mine)     { create(:tracked_playlist, name: 'My Road Trip') }
  let!(:theirs)   { create(:tracked_playlist, name: 'Their Road Trip') }
  let!(:inactive) { create(:tracked_playlist, name: 'Gone Private Road Trip', active: false) }
  let!(:favorite) { create(:favorite_playlist, user: user, tracked_playlist: mine) }

  before do
    create(:playlist_snapshot, tracked_playlist: mine,     playlist_items: playlist_items('mine1' => { title: 'Highway Song' }))
    create(:playlist_snapshot, tracked_playlist: theirs,   playlist_items: playlist_items('their1' => { title: 'Highway Tune' }))
    create(:playlist_snapshot, tracked_playlist: inactive, playlist_items: playlist_items('gone1' => { title: 'Highway Hidden' }))
  end

  it "requires a signed in user" do
    get "/search", params: { q: "highway" }
    expect(response).to redirect_to(new_user_session_path)
  end

  context "when signed in" do
    before { sign_in user }

    it "searches only my playlists by default" do
      get "/search", params: { q: "highway" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("watch?v=mine1")
      expect(response.body).not_to include("watch?v=their1")
      expect(response.body).to include(favorite_playlist_path(favorite))
    end

    it "searches all active playlists when asked" do
      get "/search", params: { q: "road trip", scope: "all" }

      expect(response.body).to include("My", "Their")
      expect(response.body).to include(playlist_history_path(theirs.playlist_id))
      expect(response.body).not_to include("Gone Private")
    end

    it "still searches my own inactive playlists in all playlists" do
      create(:favorite_playlist, user: user, tracked_playlist: inactive)

      get "/search", params: { q: "highway hidden", scope: "all" }

      expect(response.body).to include("watch?v=gone1")
    end

    it "falls back to my playlists for an unknown scope" do
      get "/search", params: { q: "highway", scope: "everything" }

      expect(response.body).not_to include("watch?v=their1")
    end

    it "returns only the results list for requests made while typing" do
      get "/search", params: { q: "highway" }, xhr: true

      expect(response.body).to include("watch?v=mine1")
      expect(response.body).not_to include("<html")
      expect(response.body).not_to include("search-input")
    end

it "shows the full description with every match highlighted in a collapsible section" do
  create(:playlist_snapshot, tracked_playlist: mine, playlist_items: playlist_items(
    "lyrics1" => { title: "Older", description: "First verse\nhighway one\nchorus\nhighway two" },
  ))

  get "/search", params: { q: "highway" }

  section = Nokogiri::HTML(response.body).at_css("details.video-full-description")
  expect(section.at_css("summary").text).to eq("Show full description (2 matches)")
  expect(section.css("mark").map(&:text)).to eq(["highway", "highway"])
  expect(section.text).to include("First verse\nhighway one")
end

it "leaves out the description section when the description has no matches" do
  get "/search", params: { q: "highway" }

  expect(response.body).not_to include("video-full-description")
end

    it "suggests searching all playlists when mine have no matches" do
      get "/search", params: { q: "zzzzqqqq" }

      expect(response.body).to include("No matches")
      expect(response.body).to include("Try all playlists")
    end
  end
end
