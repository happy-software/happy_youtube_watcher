require 'yt'
require 'playlist_difference_calculator'
require 'youtube_watcher/slacker'

class PlaylistSnapshot < ApplicationRecord
  belongs_to :tracked_playlist, foreign_key: :playlist_id, primary_key: :playlist_id
  BROKEN_STATUSES = ['Deleted video', 'Private video']

  def self.capture_all_tracked_playlists!
    TrackedPlaylist.all.each do |tp|
      current_playlist_items = get_working_songs(get_playlist_items_from_yt(tp.playlist_id))
      latest_snapshot = PlaylistSnapshot.where(playlist_id: tp.playlist_id).where("created_at < ?", DateTime.now).newest
      previous_playlist_items = get_working_songs(latest_snapshot.playlist_items)

      diff = PlaylistDifferenceCalculator.calculate_diffs(current_playlist_items, previous_playlist_items)

      if diff.any_changes?
        PlaylistSnapshot.create!(playlist_id: tp.playlist_id, playlist_items: current_playlist_items)
        playlist_name = TrackedPlaylist.find_by_playlist_id(tp.playlist_id)&.name
        PlaylistDifferenceRenderer.post_diff(diff, tp.playlist_id, playlist_name)
      end

    rescue Yt::Errors::RequestError => e
      message = """
      There was an error trying to update a playlist!
      Playlist ID: #{tp.playlist_id}
      Playlist Name: #{tp.name}
      Error Message: #{e.message}
      Backtrace: #{e.backtrace.join("\n")}
      """
      YoutubeWatcher::Slacker.post_message(message, "#happy-alerts")
    end
  end

  def self.shuffle_playlists(playlist_ids)
    playlists = playlist_ids.map { |id| PlaylistSnapshot.where(playlist_id: id).newest }.compact
    playlists.flat_map(&:shuffled_working_songs).compact.shuffle
  end

  def self.get_working_songs(playlist_items)
    playlist_items.reject { |_, song| BROKEN_STATUSES.include?(song['title']) }
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

    playlist_items
  end
end
