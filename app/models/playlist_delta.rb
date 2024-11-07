class PlaylistDelta < ApplicationRecord
  belongs_to :playlist_snapshot
  belongs_to :tracked_playlist

  def change_datetime
    playlist_snapshot.created_at
  end
end
