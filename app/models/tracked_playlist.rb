class TrackedPlaylist < ApplicationRecord
  class InvalidPlaylistId < StandardError; end

  validates_presence_of :playlist_id
  validates :playlist_id, length: {minimum: 2, message: "Playlist ID isn't long enough. Are you sure it's a valid ID?"}
  validates :playlist_id, uniqueness: {message: "This playlist is already being tracked."}

  has_many :playlist_snapshots, foreign_key: :playlist_id, primary_key: :playlist_id
  has_many :playlist_deltas

  after_create :notify_slack

  def notify_slack
    YoutubeWatcher::Slacker.post_message("New tracked playlist (#{self.name}) added!", "#happy-alerts")
  end

  def self.get_history(playlist_id, page)
    playlist = find_by_playlist_id(playlist_id)
    deltas = playlist.playlist_deltas
                     .joins(:playlist_snapshot)
                     .select('playlist_delta.*, playlist_snapshots.created_at')
                     .order('playlist_snapshots.created_at DESC')
                     .page(page)
                     .per(50)
    initial_snapshot_count = playlist.playlist_snapshots.oldest.playlist_items.count

    {
      name:          playlist.name,
      changes:       deltas,
      created_at:    playlist.created_at,
      initial_count: initial_snapshot_count,
    }
  end

  def untrack!
    self.active = false
    self.save!
  end
end
