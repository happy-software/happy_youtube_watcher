require 'rails_helper'

RSpec.describe "FavoritePlaylists", type: :request do
  let(:user) { create(:user) }
  let(:tracked_playlist) { create(:tracked_playlist) }
  let(:playlist_params) { { favorite_playlist: { playlist_id: "https://www.youtube.com/playlist?list=#{tracked_playlist.playlist_id}" } } }
  let(:tracked_events) { [] }

  before do
    sign_in user
    allow(TrackPlaylist).to receive(:call).and_return(tracked_playlist)
    allow_any_instance_of(Ahoy::Tracker).to receive(:track) do |_tracker, name, properties = {}|
      tracked_events << [name.to_s, properties]
    end
  end

  describe "POST /favorite_playlists with a playlist URL" do
    # Runs the real TrackPlaylist.call, so the URL actually gets parsed. The playlist is already tracked,
    # so TrackPlaylist finds it in the database and never calls the YouTube API.
    before { allow(TrackPlaylist).to receive(:call).and_call_original }

    it "favorites the playlist the URL points to" do
      expect {
        post favorite_playlists_path, params: playlist_params
      }.to change { user.favorite_playlists.count }.by(1)

      expect(response).to redirect_to(favorite_playlists_path)
      expect(user.favorite_playlists.last.tracked_playlist).to eq(tracked_playlist)
    end
  end

  describe "POST /favorite_playlists tracking" do
    def created_events
      tracked_events.select { |name, _| name == "favorite_playlist_created" }
    end

    it "records which button opened the add playlist modal" do
      post favorite_playlists_path, params: playlist_params.merge(source: "no_results")

      expect(response).to redirect_to(favorite_playlists_path)
      expect(created_events).to eq([["favorite_playlist_created", { source: "no_results" }]])
    end

    it "ignores unknown sources" do
      post favorite_playlists_path, params: playlist_params.merge(source: "something-else")

      expect(created_events).to eq([["favorite_playlist_created", {}]])
    end

    it "keeps the source on the form when the playlist URL is invalid" do
      allow(TrackPlaylist).to receive(:call).and_raise(TrackedPlaylist::InvalidPlaylistId)

      post favorite_playlists_path, params: playlist_params.merge(source: "no_results")

      expect(response).to have_http_status(:unprocessable_content)
      expect(created_events).to be_empty
      expect(Nokogiri::HTML(response.body).at_css('input[type="hidden"][name="source"]')["value"]).to eq("no_results")
    end
  end
end
