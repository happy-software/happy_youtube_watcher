module Youtube
  class QuotaExceededError < StandardError
    REASON = 'quotaExceeded'.freeze

    # Yt raises a running out of quota as a plain Forbidden error, so the reason YouTube sent back is the only way to tell
    def self.match?(error)
      case error
      when QuotaExceededError       then true
      when Yt::Errors::RequestError then error.reasons.include?(REASON)
      else false
      end
    end
  end
end
