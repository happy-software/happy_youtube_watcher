class TrackedPlaylist < ApplicationRecord
  validates_presence_of :playlist_id
  validates :playlist_id, length: {minimum: 2, message: "Playlist ID isn't long enough. Are you sure it's a valid ID?"}
  validates :playlist_id, uniqueness: {message: "This playlist is already being tracked."}

  has_many :playlist_snapshots, foreign_key: :playlist_id, primary_key: :playlist_id
  has_many :playlist_deltas

  def self.get_history(playlist_id, page)
    playlist = find_by_playlist_id(playlist_id)
    deltas = playlist.playlist_deltas
                     .joins(:playlist_snapshot)
                     .select('playlist_delta.*, playlist_snapshots.created_at')
                     .order('playlist_snapshots.created_at DESC')
                     .page(page)
                     .per(50)

    {
      name:    playlist.name,
      changes: deltas,
    }
  end

  def untrack!
    self.active = false
    self.save!
  end
end
