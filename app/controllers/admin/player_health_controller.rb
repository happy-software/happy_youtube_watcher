class Admin::PlayerHealthController < Admin::BaseController
  # Client-side events that signal a degraded or broken playback experience.
  PLAYER_ISSUE_EVENTS = %w[
    on_error_triggered
    player_watchdog_frozen
    player_watchdog_buffering_timeout
    player_watchdog_unexpected_unstarted
  ].freeze

  def index
    issues = Ahoy::Event.where(name: PLAYER_ISSUE_EVENTS)

    @summary = issues
      .where("time >= ?", 7.days.ago)
      .group(:name)
      .order(Arel.sql("COUNT(*) DESC"))
      .pluck(:name, Arel.sql("COUNT(*)"), Arel.sql("MAX(time)"))

    @recent = issues.includes(:user, :visit).order(time: :desc).limit(50)
  end
end
