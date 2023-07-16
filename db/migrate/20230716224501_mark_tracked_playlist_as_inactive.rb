class MarkTrackedPlaylistAsInactive < ActiveRecord::Migration[6.1]
  def change
    add_column(:tracked_playlists, :active, :boolean, default: true)
  end
end
