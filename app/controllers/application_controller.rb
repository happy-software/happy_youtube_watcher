class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :track_event

  def json_response(object, status = :ok)
    render json: object, status: status
  end

  def track_event
    ahoy.track "#{controller_path}##{action_name}", current_user_id: current_user&.id
  end
end
