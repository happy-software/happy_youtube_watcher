class Admin::UserVisitEventsController < Admin::BaseController
  def show
    @visit = Ahoy::Visit.find(params[:user_visit_id])
    @event = @visit.events.find(params[:id])
  end
end
