require 'youtube_watcher/slacker'

# This class is responsible for preparing a message for Slack to show the changes in a playlist
class PlaylistDifferenceRenderer
  def self.post_diff(diffs, playlist_id, playlist_name)
    message = create_diff_message(diffs, playlist_id, playlist_name)
    ::YoutubeWatcher::Slacker.post_message(message, '#happy-hood')
  end

  def self.create_diff_message(diffs, playlist_id, playlist_name)
    s =  [""]
    s += ["These songs were removed:\n ```#{diffs.removed_songs.map { |song| "Position: #{song.position} - #{song.title} - ID(#{song.url})"}.join("\n")}```"] if diffs.removed_songs.any?
    s += ["These songs were added:\n```#{diffs.added_songs.map { |song| "Position: #{song.position} - #{song.title} - ID(#{song.url})"}.join("\n")}```"]      if diffs.added_songs.any?

    return '' unless s.count > 1 # Not just empty string

    s = s.join("\n")
    "#{playlist_name} - (https://youtube.com/playlist?list=#{playlist_id}) - #{Date.today.readable_inspect}\n\n" + s
  end
end
