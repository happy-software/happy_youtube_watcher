class FavoritePlaylists::MixesController < ApplicationController
  before_action :authenticate_user! # TODO: Move this into ApplicationController once we've migrated all SYT routes over

  def index
    @favorite_playlists = current_user.favorite_playlists.order(created_at: :desc)
    @discover_playlists = TrackedPlaylist.where.not(id: [@favorite_playlists.pluck(:tracked_playlist_id)])
  end
end
