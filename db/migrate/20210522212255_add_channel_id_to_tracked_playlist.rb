class AddChannelIdToTrackedPlaylist < ActiveRecord::Migration[6.1]
  def change
    add_column :tracked_playlists, :channel_id, :string
    add_index :tracked_playlists, :channel_id
  end
end
