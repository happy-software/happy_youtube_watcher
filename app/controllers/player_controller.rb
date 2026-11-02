class PlayerController < ApplicationController
  before_action :authenticate_user! # TODO: Move this into ApplicationController once we've migrated all SYT routes over

  def index
    # params.expect(:selected_playlist_ids)
    @tracked_playlists = TrackedPlaylist.where(id: params[:selected_playlist_ids])
    @video_ids = @tracked_playlists.flat_map { |p| p.playlist_snapshots.newest.playlist_items.keys }.sample(210).shuffle
    @start_stop_times = current_user.video_settings.start_stop_times.where(video_id: @video_ids).to_h { |vs| [vs.video_id, vs.settings] }
    ahoy.track 'create_mix', combined_playlists: @tracked_playlists.pluck(:id, :name), videos: @video_ids
  end
end
