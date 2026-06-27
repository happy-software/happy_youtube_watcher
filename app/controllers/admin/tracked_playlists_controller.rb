class Admin::TrackedPlaylistsController < Admin::BaseController
  def index
    @tracked_playlists = TrackedPlaylist
      .left_joins(:favorite_playlists)
      .select("tracked_playlists.*, COUNT(favorite_playlists.id) AS favorites_count")
      .group("tracked_playlists.id")
      .order(created_at: :desc)
      .page(params[:page])
      .per(25)
  end

  def show
    @playlist        = TrackedPlaylist.find(params[:id])
    @newest_snapshot = @playlist.playlist_snapshots.newest
    @snapshot_count  = @playlist.playlist_snapshots.count
    @favoriters      = @playlist.favorite_playlists.includes(:user).order(created_at: :desc)
  end
end
