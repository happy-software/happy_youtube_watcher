class AddCreatedAtIndexToPlaylistSnapshot < ActiveRecord::Migration[6.1]
  def change
    add_index :playlist_snapshots, :created_at
  end
end
