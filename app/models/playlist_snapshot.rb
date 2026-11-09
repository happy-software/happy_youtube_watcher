require 'yt'
require_relative '../services/playlist_difference_calculator'
require 'youtube_watcher/slacker'

class PlaylistSnapshot < ApplicationRecord
  belongs_to :tracked_playlist, foreign_key: :playlist_id, primary_key: :playlist_id
  has_one :playlist_delta

  after_create_commit :rebuild_search_entries

  BROKEN_STATUSES = ['Deleted video', 'Private video']

  scope :newest_per_playlist, -> { where(id: select("DISTINCT ON (playlist_id) id").order(:playlist_id, created_at: :desc)) }

  def self.capture_all_tracked_playlists!
    outcomes = Hash.new(0)

    usage = Youtube::QuotaUsage.track do |current|
      capture_tracked_playlists(outcomes)
    rescue StandardError => e
      # DailySnapshotWorker doesn't retry (a retry spends the quota again), so this alert is the only notice of the failure.
      # Playlists the run didn't reach get picked up by the next day's run.
      post_quota_usage(current, outcomes, error: e)
      raise
    end

    post_quota_usage(usage, outcomes)
  end

  def self.post_quota_usage(usage, outcomes, error: nil)
    crash = <<~CRASH if error
      Daily snapshots crashed with #{error.class}: #{error.message}
      It won't be retried. The next daily run picks up the playlists it didn't reach.
    CRASH
    message = <<~MESSAGE
      #{crash}Daily snapshots used #{usage} of the YouTube API quota.
      Playlists: #{outcomes[:fetched]} fetched (etag changed), #{outcomes[:rechecked]} availability re-checks, #{outcomes[:unchanged]} unchanged, #{outcomes[:failed]} deactivated after errors.
    MESSAGE
    Rails.logger.info(message)
    YoutubeWatcher::Slacker.post_message(message, "#happy-alerts")
  end

  def self.capture_tracked_playlists(outcomes)
    TrackedPlaylist.where(active: true).order(:id).each do |tp|
      outcomes[tp.create_snapshot] += 1
    rescue Yt::Errors::RequestError, Youtube::EtagFetchError, Youtube::QuotaExceededError => e
      if Youtube::QuotaExceededError.match?(e)
        # Every request after this fails too, so stop here instead of deactivating all the remaining playlists
        YoutubeWatcher::Slacker.post_message(<<~MESSAGE, "#happy-alerts")
          Ran out of YouTube API quota during the daily snapshots!
          Stopped at playlist #{tp.playlist_id} (#{tp.name}). It and the playlists after it were skipped and will be retried on the next run.
        MESSAGE
        break
      end
      outcomes[:failed] += 1

      tp.active = false; tp.save!
      # Filtering backtrace gems and making the output to slack gigantic
      #   Note: this may cause 3rd party gem issues to get hidden though.
      filtered_backtrace = e.backtrace.reject { |line| line.include?("/usr/local/bundle") }
      message = """
      There was a #{e.class} error trying to update a playlist!
      Automatically deactivating the playlist in order to avoid future exceptions.
      It will have to be manually activated in order to get pulled from the daily snapshots again.
      Playlist ID: #{tp.playlist_id}
      Playlist Name: #{tp.name}
      Error Message: #{e.message}
      Filtered Backtrace:
      #{filtered_backtrace.join("\n")}
      """
      YoutubeWatcher::Slacker.post_message(message, "#happy-alerts")
    end
  end

  def self.shuffle_playlists(playlist_ids)
    playlists = playlist_ids.map { |id| PlaylistSnapshot.where(playlist_id: id).newest }.compact
    playlists.flat_map(&:shuffled_working_songs).compact.shuffle
  end

  def self.get_working_songs(playlist_items)
    playlist_items.reject { |_, song| unavailable?(song) }
  end

  def self.unavailable?(song)
    # Comparing the title is kind of brittle since someone could create a legitimate video with a title called:
    #   - "Private video" or "Deleted video"
    # The `Youtube::VideoAvailabilityChecker` service was created to check the status of the video using the API instead of
    # trying to infer from the video title.
    BROKEN_STATUSES.include?(song['title']) || song[Youtube::VideoAvailabilityChecker::REASON_KEY].present?
  end

  def shuffled_working_songs
    working_songs = PlaylistSnapshot.get_working_songs(playlist_items)
    songs = working_songs.slice(*working_songs.keys.shuffle)
    songs.map do |video_id, song_info|
      {
        title:       song_info.dig('title'),
        video_id:    video_id,
        playlist_id: playlist_id,
        description: song_info.dig('description'),
        playlist_owner: song_info.dig('channelTitle'),
      }
    end
  end

  def self.get_playlist_items_from_yt(playlist_id)
    playlist       = Yt::Playlist.new(id: playlist_id)
    all_songs      = playlist.playlist_items.where
    playlist_items = {}
    song_count     = 0

    all_songs.each do |song|
      song_count += 1
      song_id = song.snippet.data['resourceId']['videoId']
      playlist_items[song_id] = song.snippet.data
    end
    # Yt pages through the playlist 50 items at a time, and even an empty playlist takes 1 request
    Youtube::QuotaUsage.record('playlistItems', [(song_count / 50.0).ceil, 1].max)

    Youtube::VideoAvailabilityChecker.annotate(playlist_items)
  end

  def self.in_diff_notification_deny_list?(tracked_playlist)
    # Playlists we don't care about getting notifications for in production
    return false unless Rails.env.production?
    FavoritePlaylist.where(user_id: [1,2,4]).pluck(:tracked_playlist_id).exclude?(tracked_playlist.id)
  end

  private

  def rebuild_search_entries
    VideoSearchEntry.rebuild_from(PlaylistSnapshot.where(id: id))
  end
end
