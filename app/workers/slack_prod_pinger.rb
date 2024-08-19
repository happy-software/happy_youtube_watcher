class SlackProdPinger
  include Sidekiq::Worker

  def perform
    return unless ENV["ENABLE_SLACK_PROD_PINGER"]

    hostname = `hostname -A`.strip
    message = "SlackProdPinger - Hello from #{hostname}!\nYou can toggle this message on and off with the `ENABLE_SLACK_PROD_PINGER` env var."

    YoutubeWatcher::Slacker.post_message(message, "#happy-alerts")
  end
end
