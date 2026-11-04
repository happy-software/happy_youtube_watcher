class AddLastEtagToTrackedPlaylists < ActiveRecord::Migration[8.1]
  def up
    # The etag YouTube returned the last time the daily snapshot checked the playlist, whether or not a snapshot got created
    add_column :tracked_playlists, :last_etag, :string

    # Start from the etag on each playlist's newest snapshot. Playlists without one get a full fetch on the next run, which fills it in.
    execute <<~SQL
      UPDATE tracked_playlists tp
      SET last_etag = newest.etag
      FROM (
        SELECT DISTINCT ON (playlist_id) playlist_id, etag
        FROM playlist_snapshots
        ORDER BY playlist_id, created_at DESC
      ) newest
      WHERE newest.playlist_id = tp.playlist_id
    SQL
  end

  def down
    remove_column :tracked_playlists, :last_etag
  end
end
