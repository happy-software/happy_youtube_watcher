class TrackedPlaylistsController < ApplicationController
  def index
    tps = TrackedPlaylist.all.map { |tp| {playlist_id: tp.playlist_id, name: tp.name, is_default: tp.is_default} }.sort_by { |tp| tp[:name] }
    json_response(tps)
  end

  def create
    playlist_info = Yt::Playlist.new(id: params[:playlist_id])

    tp = TrackedPlaylist.create!(
      playlist_id: params[:playlist_id],
      channel_id: playlist_info.channel_id,
      name:        "#{playlist_info.channel_title} - #{playlist_info.title}",
      is_default:  !!params[:is_default],
      channel_id:  playlist_info.channel_id,
    )

    PlaylistSnapshot.create!(
      playlist_id: params[:playlist_id],
      playlist_items: PlaylistSnapshot.get_playlist_items_from_yt(params[:playlist_id])
    )

    json_response(tp, :created)
  end
end
