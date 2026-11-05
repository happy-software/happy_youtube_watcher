# A flattened, searchable copy of the videos in the newest snapshot of each tracked playlist.
# Rebuilt whenever a playlist gets a new snapshot (see PlaylistSnapshot#rebuild_search_entries).
class VideoSearchEntry < ApplicationRecord
  belongs_to :tracked_playlist

  # Replaces the entries for every playlist in `snapshots` with the videos from those snapshots.
  # Pass only the newest snapshot per playlist, otherwise older snapshots will clobber newer ones.
  def self.rebuild_from(snapshots)
    snapshot_ids = snapshots.select(:id).to_sql

    transaction do
      where(tracked_playlist_id: TrackedPlaylist.joins(:playlist_snapshots).where("playlist_snapshots.id IN (#{snapshot_ids})").select(:id)).delete_all

      connection.exec_insert(sanitize_sql_array([<<~SQL, broken_statuses: PlaylistSnapshot::BROKEN_STATUSES, reason_key: Youtube::VideoAvailabilityChecker::REASON_KEY]))
        INSERT INTO video_search_entries
          (tracked_playlist_id, video_id, title, channel_title, description, thumbnail_url, position, created_at, updated_at)
        SELECT
          tp.id,
          item.key,
          item.value->>'title',
          item.value->>'videoOwnerChannelTitle',
          item.value->>'description',
          COALESCE(item.value#>>'{thumbnails,medium,url}', item.value#>>'{thumbnails,high,url}', item.value#>>'{thumbnails,default,url}'),
          (item.value->>'position')::integer,
          NOW(),
          NOW()
        FROM playlist_snapshots s
        JOIN tracked_playlists tp ON tp.playlist_id = s.playlist_id
        CROSS JOIN LATERAL jsonb_each(s.playlist_items) AS item
        WHERE s.id IN (#{snapshot_ids})
          AND COALESCE(item.value->>'title', '') NOT IN (:broken_statuses)
          AND NOT jsonb_exists(item.value, :reason_key)
      SQL
    end
  end
end
