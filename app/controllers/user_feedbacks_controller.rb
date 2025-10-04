class UserFeedbacksController < ApplicationController
  def new
    @feedback = UserFeedback.new
  end

  def create
    @feedback      = UserFeedback.new(feedback_params)
    @feedback.user = current_user

    if @feedback.save
      redirect_to root_path, notice: "Thanks for your feedback!"
    else
      render :new, status: :unprocessable_entity, notice: @feedback.errors
    end
  end

  private

  def feedback_params
    params.require(:user_feedback).permit(:message, :email)
  end
end
