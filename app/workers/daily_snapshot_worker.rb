class DailySnapshotWorker
  include Sidekiq::Worker

  # A retry runs every playlist again and spends the YouTube quota again. A failure is posted to Slack instead
  # (see PlaylistSnapshot.capture_all_tracked_playlists!), and the next day's run picks up the skipped playlists.
  sidekiq_options retry: false

  def perform
    PlaylistSnapshot.capture_all_tracked_playlists!
  end
end
