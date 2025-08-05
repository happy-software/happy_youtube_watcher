class FavoritePlaylistsController < ApplicationController
  before_action :authenticate_user! # TODO: Move this into ApplicationController once we've migrated all SYT routes over
  before_action :set_favorite_playlist, only: %i[ show edit update destroy ]

  # GET /favorite_playlists or /favorite_playlists.json
  def index
    @favorite_playlists = current_user.favorite_playlists
  end

  # GET /favorite_playlists/1 or /favorite_playlists/1.json
  def show
  end

  # GET /favorite_playlists/new
  def new
    @favorite_playlist = FavoritePlaylist.new
  end

  # GET /favorite_playlists/1/edit
  def edit
  end

  # POST /favorite_playlists or /favorite_playlists.json
  def create
    tracked_playlist = TrackPlaylist.call(favorite_playlist_params[:playlist_id])
    @favorite_playlist = FavoritePlaylist.new(tracked_playlist: tracked_playlist, user: current_user)

    respond_to do |format|
      if @favorite_playlist.save
        format.html { redirect_to @favorite_playlist, notice: "Favorite playlist was successfully created." }
        format.json { render :show, status: :created, location: @favorite_playlist }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @favorite_playlist.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /favorite_playlists/1 or /favorite_playlists/1.json
  def update
    respond_to do |format|
      if @favorite_playlist.update(favorite_playlist_params)
        format.html { redirect_to @favorite_playlist, notice: "Favorite playlist was successfully updated." }
        format.json { render :show, status: :ok, location: @favorite_playlist }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @favorite_playlist.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /favorite_playlists/1 or /favorite_playlists/1.json
  def destroy
    @favorite_playlist.destroy!

    respond_to do |format|
      format.html { redirect_to favorite_playlists_path, status: :see_other, notice: "Favorite playlist was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_favorite_playlist
      @favorite_playlist = FavoritePlaylist.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def favorite_playlist_params
      params.expect(favorite_playlist: [ :playlist_id ])
    end
end
