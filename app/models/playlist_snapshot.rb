require 'yt'
require 'youtube_watcher/slacker'
require 'playlist_difference_calculator'

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
        post_diff!(diff, tp.playlist_id)
      end
    end
  end

  def self.post_diff!(diffs, playlist_id)
    message = create_diff_message(diffs, playlist_id)
    ::YoutubeWatcher::Slacker.post_message(message, '#happy-hood')
  end

  def self.create_diff_message(diffs, playlist_id)
    s =  [""]
    s += ["These songs were removed:\n ```#{diffs.removed_songs.map { |song| "Position: #{song.position} - #{song.title} - ID(#{song.url})"}.join("\n")}```"] if diffs.removed_songs.any?
    s += ["These songs were added:\n```#{diffs.added_songs.map { |song| "Position: #{song.position} - #{song.title} - ID(#{song.url})"}.join("\n")}```"]      if diffs.added_songs.any?

    return '' unless s.count > 1 # Not just empty string

    s = s.join("\n")
    "#{TrackedPlaylist.where(playlist_id: playlist_id).first&.name} - (https://youtube.com/playlist?list=#{playlist_id}) - #{Date.today.readable_inspect}\n\n" + s
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
    all_songs      = playlist.playlist_items.where;
    playlist_items = {}

    all_songs.each do |song|
      song_id = song.snippet.data['resourceId']['videoId']
      playlist_items[song_id] = song.snippet.data
    end

    playlist_items
  end

  private

  # Helpers that can eventually be refactored out of this class

  def self.url(id)
    # TODO: This method is presentation logic, needs to move out of the model
    "https://youtube.com/watch?v=#{id}"
  end
end
