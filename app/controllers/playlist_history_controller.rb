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
    @history = TrackedPlaylist.get_history(playlist_id)
  end
end
