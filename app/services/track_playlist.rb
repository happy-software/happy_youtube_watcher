class TrackPlaylist
  def self.call(raw_playlist_id, is_default: false)
    # Check to see if the playlist is already tracked, if so return the playlist
    # Otherwise, create a new tracked playlist and return it

    playlist_id = get_playlist_id_from_raw(raw_playlist_id)
    playlist = TrackedPlaylist.find_by_playlist_id(playlist_id)
    return playlist if playlist.present?

    playlist_info = Yt::Playlist.new(id: playlist_id)
    begin
      tp = TrackedPlaylist.new(
        playlist_id: playlist_id,
        name:        "#{playlist_info.channel_title} - #{playlist_info.title}",
        is_default:  is_default,
        channel_id:  playlist_info.channel_id,
      )

      if tp.save
        PlaylistSnapshot.create!(
          playlist_id: playlist_id,
          playlist_items: PlaylistSnapshot.get_playlist_items_from_yt(playlist_id)
        )

        return tp
      else
        raise StandardError, "Failed to save TrackedPlaylist: #{tp.errors.map(&:full_message)}"
      end
    end
  end

  def self.get_playlist_id_from_raw(playlist_id)
    # Converts the youtube url if that's what is passed in
    # e.g. https://www.youtube.com/playlist?list=PL8g7AzKjYPsNXA56I9GjB4hz3Z39NSrwN => PL8g7AzKjYPsNXA56I9GjB4hz3Z39NSrwN

    uri = URI(playlist_id)
    CGI::parse(uri.query)["list"]&.first
  end
end
