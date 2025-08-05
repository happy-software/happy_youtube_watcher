class PlayerController < ApplicationController
  before_action :authenticate_user! # TODO: Move this into ApplicationController once we've migrated all SYT routes over

  def index
    # params.expect(:selected_playlist_ids)
    @tracked_playlists = TrackedPlaylist.where(id: params[:selected_playlist_ids])
    @video_ids = @tracked_playlists.flat_map { |p| p.playlist_snapshots.newest.playlist_items.keys }.sample(210).shuffle

  end
end
