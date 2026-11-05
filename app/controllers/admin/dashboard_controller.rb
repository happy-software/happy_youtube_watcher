class Admin::DashboardController < Admin::BaseController
  def index
    @stats = {
      user_count:             User.count,
      new_users_7d:           User.where("created_at >= ?", 7.days.ago).count,
      new_users_30d:          User.where("created_at >= ?", 30.days.ago).count,
      tracked_playlist_count: TrackedPlaylist.count,
      mixes_created_7d:       Ahoy::Event.where(name: "create_mix").where("time >= ?", 7.days.ago).count,
      events_last_24h:        Ahoy::Event.where("time >= ?", 24.hours.ago).count,
      player_issues_7d:       Ahoy::Event.where(name: Admin::PlayerHealthController::PLAYER_ISSUE_EVENTS)
                                         .where("time >= ?", 7.days.ago).count,
    }
  end
end
