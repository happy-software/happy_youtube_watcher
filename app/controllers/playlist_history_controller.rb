class PlaylistHistoryController < ApplicationController
  def index
    @playlists = TrackedPlaylist.all.map do |playlist|
      {
        playlist_id: playlist.playlist_id,
        name:        playlist.name
      }
    end
  end

  def show
    playlist_id = params[:playlist_id]
    page        = params[:page] || 1
    @history    = TrackedPlaylist.get_history(playlist_id, page)

    respond_to do |format|
      format.html # renders the full page for normal requests
    end
  end

  def load_more_history
    playlist_id = params[:playlist_id]
    page        = params[:page]
    @history    = TrackedPlaylist.get_history(playlist_id, page)

    render partial: 'load_more_history'
  end

  def action_details
    {
      playlist_id: params[:playlist_id],
      page:        params[:page],
    }
  end
end
