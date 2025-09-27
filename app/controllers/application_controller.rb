class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :track_event

  def json_response(object, status = :ok)
    render json: object, status: status
  end

  def track_event
    headers = request.headers.to_h.reject { |k,v| ['puma', 'action_dispatch', 'honeybadger', 'rack', 'action_controller'].any? { |word| k.to_s.downcase.include?(word) } }
    ahoy.track action_name, current_user_id: current_user&.id, **request.path_parameters, **headers
  end
end
