class Admin::UsersController < Admin::BaseController
  def index
    @users = User
      .left_joins(:favorite_playlists)
      .select("users.*, COUNT(favorite_playlists.id) AS favorites_count")
      .group("users.id")
      .order("users.created_at DESC")
  end

  def show
    @user = User.find(params[:id])
    @favorite_playlists = @user.favorite_playlists
                               .includes(:tracked_playlist)
                               .order(created_at: :desc)
  end
end
