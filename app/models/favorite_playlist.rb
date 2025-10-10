class FavoritePlaylist < ApplicationRecord
  belongs_to :user
  belongs_to :tracked_playlist

  def name
    tracked_playlist.name
  end

  def playlist_items
    tracked_playlist.playlist_snapshots.newest.playlist_items
  end
end
