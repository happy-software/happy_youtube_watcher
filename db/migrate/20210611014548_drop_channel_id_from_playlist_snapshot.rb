class DropChannelIdFromPlaylistSnapshot < ActiveRecord::Migration[6.1]
  def change
    remove_column :playlist_snapshots, :channel_id
  end
end
