class TrackedPlaylist < ApplicationRecord
  validates_presence_of :playlist_id
  validates :playlist_id, length: {minimum: 2, message: "Playlist ID isn't long enough. Are you sure it's a valid ID?"}
  validates :playlist_id, uniqueness: {message: "This playlist is already being tracked."}

  has_many :playlist_snapshots, foreign_key: :playlist_id, primary_key: :playlist_id
end
