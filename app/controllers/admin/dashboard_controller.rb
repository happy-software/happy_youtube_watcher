class Admin::DashboardController < Admin::BaseController
  def index
    @stats = {
      user_count:             User.count,
      tracked_playlist_count: TrackedPlaylist.count,
      events_last_24h:        Ahoy::Event.where("time >= ?", 24.hours.ago).count
    }
  end
end
