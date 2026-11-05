class Admin::UserVisitsController < Admin::BaseController
  def index
    @visits = Ahoy::Visit.includes(:user).order(started_at: :desc)

    if params[:user_id].present?
      @filtered_user = User.find_by(id: params[:user_id])
      @visits = @visits.where(user_id: params[:user_id])
    end

    @visits = @visits.page(params[:page]).per(50)
  end

  def show
    @visit = Ahoy::Visit.find(params[:id])
  end
end
