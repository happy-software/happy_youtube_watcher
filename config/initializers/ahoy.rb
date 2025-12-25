class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = true

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = true
Ahoy.job_queue = :default

# TODO: If you figure out a way to get the real IP address attached to `ip.remote_ip` from the `HTTP_CF_CONNECTING_IP`
#       header, then remove this monkey patch. Hopefully it won't break anything in the future =)
# Monkey-patch how the IP address gets stored in Ahoy::Visit since
# Cloudflare tunnel is being used and that causes the IP to get saved as
# `::1`
module Ahoy
  class VisitProperties
    def ip
      ip = if request.remote_ip.in?(["::1"]) && request.headers["HTTP_CF_CONNECTING_IP"].present?
        request.headers["HTTP_CF_CONNECTING_IP"]
      else
        request.remote_ip
      end

      if ip && Ahoy.mask_ips
        Ahoy.mask_ip(ip)
      else
        ip
      end
    end
  end
end
