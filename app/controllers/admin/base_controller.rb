class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user&.is_admin?
  end
end
