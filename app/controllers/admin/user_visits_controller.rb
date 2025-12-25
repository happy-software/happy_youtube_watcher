class Admin::UserVisitsController < Admin::BaseController
  def index
    @visits = Ahoy::Visit.order(started_at: :desc)
  end

  def show
    @visit = Ahoy::Visit.find(params[:id])
  end
end
