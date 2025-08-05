class TrackedPlaylistsController < ApplicationController
  def index
    tps = TrackedPlaylist.all.map { |tp| {playlist_id: tp.playlist_id, name: tp.name, is_default: tp.is_default} }.sort_by { |tp| tp[:name] }
    json_response(tps)
  end

  def create
    # TODO: This can probably be deprecated because this was used for the old React frontend and has
    #       been replaced by FavoritePlaylists now.
    playlist_id = params[:playlist_id]
    playlist_info = Yt::Playlist.new(id: playlist_id)
    begin
      tp = TrackedPlaylist.new(
        playlist_id: playlist_id,
        name:        "#{playlist_info.channel_title} - #{playlist_info.title}",
        is_default:  !!params[:is_default],
        channel_id:  playlist_info.channel_id,
        )

      if tp.save
        PlaylistSnapshot.create!(
          playlist_id: playlist_id,
          playlist_items: PlaylistSnapshot.get_playlist_items_from_yt(playlist_id)
        )

        json_response(tp, :created)
      else
        json_response({errors: tp.errors.map(&:full_message)}, :unprocessable_entity)
      end
    rescue Yt::Errors::NoItems
      json_response({errors: "Playlist(#{playlist_id}) couldn't be found."}, :unprocessable_entity)
    end
  end
end
