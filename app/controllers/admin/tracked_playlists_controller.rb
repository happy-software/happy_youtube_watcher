class Admin::TrackedPlaylistsController < Admin::BaseController
  def index
    @tracked_playlists = TrackedPlaylist.order(created_at: :desc)
  end

  def show
    @playlist = TrackedPlaylist.find(params[:id])
  end
end
