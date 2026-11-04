class TrackedPlaylist < ApplicationRecord
  class InvalidPlaylistId < StandardError; end

  AVAILABILITY_CHECK_INTERVAL_DAYS = 7

  validates_presence_of :playlist_id
  validates :playlist_id, length: {minimum: 2, message: "Playlist ID isn't long enough. Are you sure it's a valid ID?"}
  validates :playlist_id, uniqueness: {message: "This playlist is already being tracked."}

  has_many :playlist_snapshots, foreign_key: :playlist_id, primary_key: :playlist_id
  has_many :playlist_deltas
  has_many :favorite_playlists
  has_many :users, through: :favorite_playlists
  has_many :video_search_entries, dependent: :delete_all

  after_create :notify_slack

  def notify_slack
    YoutubeWatcher::Slacker.post_message("New tracked playlist (#{self.name}) added!", "#happy-alerts")
  end

  def self.get_history(playlist_id, page)
    playlist = find_by_playlist_id(playlist_id)
    deltas = playlist.playlist_deltas
                     .joins(:playlist_snapshot)
                     .select('playlist_delta.*, playlist_snapshots.created_at')
                     .order('playlist_snapshots.created_at DESC')
                     .page(page)
                     .per(50)
    initial_snapshot_count = playlist.playlist_snapshots.oldest.playlist_items.count

    {
      name:          playlist.name,
      changes:       deltas,
      created_at:    playlist.created_at,
      initial_count: initial_snapshot_count,
    }
  end

  def untrack!
    self.active = false
    self.save!
  end

  def create_snapshot
    current_etag    = Youtube::PlaylistEtagFetcher.new(self.playlist_id).fetch
    latest_snapshot = self.playlist_snapshots.newest
    stored_etag     = latest_snapshot&.etag

    playlist_items = if current_etag != stored_etag
      PlaylistSnapshot.get_playlist_items_from_yt(self.playlist_id)
    elsif availability_check_due?
      # Videos can still become unavailable (e.g. region blocked) without changing the etag, so re-check the ones we have.
      Youtube::VideoAvailabilityChecker.annotate(latest_snapshot.playlist_items)
    else
      return # No change according to Youtube's API so don't make expensive call to get the full playlist.
    end

    current_playlist_items = PlaylistSnapshot.get_working_songs(playlist_items)
    previous_playlist_items = PlaylistSnapshot.get_working_songs(latest_snapshot.playlist_items)

    diff = PlaylistDifferenceCalculator.calculate_diffs(current_playlist_items, previous_playlist_items)

    if diff.any_changes?
      snapshot = PlaylistSnapshot.create!(playlist_id: self.playlist_id, playlist_items: current_playlist_items)
      delta = PlaylistDelta.create!(
        added:             diff.added_songs,
        removed:           diff.removed_songs,
        playlist_snapshot: snapshot,
        tracked_playlist:  snapshot.tracked_playlist,
      )
      ArchiveWorker.archive_videos(delta)

      playlist_name = TrackedPlaylist.find_by_playlist_id(self.playlist_id)&.name
      PlaylistDifferenceRenderer.post_diff(diff, self.playlist_id, playlist_name) unless PlaylistSnapshot.in_diff_notification_deny_list?(self)
    end

  end

  # Re-checking every video costs 1 API unit per 50 videos, so unchanged playlists only get re-checked once every
  # AVAILABILITY_CHECK_INTERVAL_DAYS days. The playlist id spreads them across the days instead of checking them all at once.
  def availability_check_due?(date = Date.current)
    id % AVAILABILITY_CHECK_INTERVAL_DAYS == date.jd % AVAILABILITY_CHECK_INTERVAL_DAYS
  end
end
