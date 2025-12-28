class AddEtagToPlaylistSnapshot < ActiveRecord::Migration[8.0]
  def change
    add_column :playlist_snapshots, :etag, :string
  end
end
