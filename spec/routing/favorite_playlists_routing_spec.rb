require "rails_helper"

RSpec.describe FavoritePlaylistsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/favorite_playlists").to route_to("favorite_playlists#index")
    end

    it "routes to #new" do
      expect(get: "/favorite_playlists/new").to route_to("favorite_playlists#new")
    end

    it "routes to #show" do
      expect(get: "/favorite_playlists/1").to route_to("favorite_playlists#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/favorite_playlists/1/edit").to route_to("favorite_playlists#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/favorite_playlists").to route_to("favorite_playlists#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/favorite_playlists/1").to route_to("favorite_playlists#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/favorite_playlists/1").to route_to("favorite_playlists#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/favorite_playlists/1").to route_to("favorite_playlists#destroy", id: "1")
    end
  end
end
