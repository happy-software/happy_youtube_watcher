class PagesController < ApplicationController
  def home
    # TODO: Remove this after confirming remote_ip works correctly in prod
    Rails.logger.warn(
      remote_addr: request.remote_addr,
      remote_ip:   request.remote_ip,
      cf_ip:       request.headers["HTTP_CF_CONNECTING_IP"]
    )
  end
end
