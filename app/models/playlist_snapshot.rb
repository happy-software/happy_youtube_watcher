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
    TrackedPlaylist.where(active: true).order(:id).each do |tp|
      tp.create_snapshot
    rescue Yt::Errors::RequestError, Youtube::EtagFetchError, Youtube::QuotaExceededError => e
      if Youtube::QuotaExceededError.match?(e)
        # Every request after this fails too, so stop here instead of deactivating all the remaining playlists
        YoutubeWatcher::Slacker.post_message(<<~MESSAGE, "#happy-alerts")
          Ran out of YouTube API quota during the daily snapshots!
          Stopped at playlist #{tp.playlist_id} (#{tp.name}). It and the playlists after it were skipped and will be retried on the next run.
        MESSAGE
        break
      end

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

    all_songs.each do |song|
      song_id = song.snippet.data['resourceId']['videoId']
      playlist_items[song_id] = song.snippet.data
    end

    Youtube::VideoAvailabilityChecker.annotate(playlist_items)
  end

  def self.in_diff_notification_deny_list?(tracked_playlist)
    # Playlists we don't care about getting notifications for in production
    return false unless Rails.env.production?
    FavoritePlaylist.where(user_id: [1,2,4]).pluck(:tracked_playlist_id).exclude?(tracked_playlist.id)
  end

  def self.playlist_etag_changed?(tracked_playlist)
    current_etag = Youtube::PlaylistEtagFetcher.new(tracked_playlist.playlist_id).fetch
    stored_etag  = tracked_playlist.playlist_snapshots.newest&.etag

    current_etag != stored_etag
  end

  private

  def rebuild_search_entries
    VideoSearchEntry.rebuild_from(PlaylistSnapshot.where(id: id))
  end
end
