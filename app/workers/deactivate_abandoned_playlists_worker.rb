class DeactivateAbandonedPlaylistsWorker
  include Sidekiq::Worker

  def perform
    TrackedPlaylist
      .where(active: true)
      .where.not(id: FavoritePlaylist.select(:tracked_playlist_id))
      .update_all(active: false)
  end
end
