class Admin::UserFeedbacksController < Admin::BaseController
  def index
    @feedbacks = UserFeedback
      .includes(:user, :rich_text_message)
      .order(created_at: :desc)
      .page(params[:page])
      .per(25)
  end

  def show
    @feedback = UserFeedback.find(params[:id])
  end
end
