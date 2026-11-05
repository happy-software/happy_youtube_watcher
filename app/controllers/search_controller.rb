class SearchController < ApplicationController
  before_action :authenticate_user!

  SCOPES = %w[mine all].freeze

  def index
    @query   = params[:q].to_s
    @scope   = SCOPES.include?(params[:scope]) ? params[:scope] : "mine"
    @results = PlaylistSearch.call(@query, tracked_playlists: searchable_playlists)
    @favorite_ids_by_tracked_playlist = current_user.favorite_playlists.pluck(:tracked_playlist_id, :id).to_h

    # The search page fetches results as you type and only needs the results list back
    render partial: "results" if request.xhr?
  end

  private

  def searchable_playlists
    mine = current_user.tracked_playlists
    return mine if @scope == "mine"

    # Inactive playlists may have been made private since we tracked them, so only show them to people who favorited them
    TrackedPlaylist.where(active: true).or(TrackedPlaylist.where(id: mine.select(:id)))
  end

  def action_details
    { q: params[:q], scope: params[:scope] }
  end
end
