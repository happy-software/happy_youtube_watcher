# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger]

  # We recommend adjusting the value in production:
  config.traces_sample_rate = 0.5
end
