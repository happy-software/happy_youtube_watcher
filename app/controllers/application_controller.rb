class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :track_event

  def json_response(object, status = :ok)
    render json: object, status: status
  end

  def track_event
    ahoy.track "#{controller_path}##{action_name}", **action_details.compact
  end

  def action_details
    # Not a perfect solution since this works at a per-controller level rather than a per-action level, but override
    # this in other controllers to add some additional context that needs to be tracked by Ahoy
    {}
  end
end
