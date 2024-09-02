class DailySnapshotWorker
  include Sidekiq::Worker

  def perform
    PlaylistSnapshot.capture_all_tracked_playlists!
  end
end
