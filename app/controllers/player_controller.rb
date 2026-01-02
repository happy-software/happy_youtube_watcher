class PlayerController < ApplicationController
  before_action :parse_playlist_ids

  def index
    @playlist_ids = params[:playlist_ids]
  end

  private

  def parse_playlist_ids
    if params[:playlist_ids].is_a?(String)
      params[:playlist_ids] = params[:playlist_ids].split(',').map(&:strip)
    end
  end
end
