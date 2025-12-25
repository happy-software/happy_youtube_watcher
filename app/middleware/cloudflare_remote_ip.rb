class CloudflareRemoteIp
  def initialize(app)
    @app = app
  end

  def call(env)
    cf_ip = env["HTTP_CF_CONNECTING_IP"]

    if cf_ip.present?
      env["HTTP_X_FORWARDED_FOR"] ||= cf_ip

      # clear memoized IPs
      env.delete("action_dispatch.remote_ip")
      env.delete("action_dispatch.client_ip")
    end

    @app.call(env)
  end
end
