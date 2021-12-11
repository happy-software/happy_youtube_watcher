class TrackedPlaylist < ApplicationRecord
  validates_presence_of :playlist_id
  validates :playlist_id, length: {minimum: 2, message: "Playlist ID isn't long enough. Are you sure it's a valid ID?"}
  validates :playlist_id, uniqueness: {message: "This playlist is already being tracked."}

  has_many :playlist_snapshots, foreign_key: :playlist_id, primary_key: :playlist_id

  def self.get_history(playlist_id)
    playlist = find_by_playlist_id(playlist_id)
    results = []
    playlist.playlist_snapshots.order(:created_at).find_each(batch_size: 1).each_cons(2) do |p|
      older, newer = p
      diff = PlaylistDifferenceCalculator.calculate_diffs(newer.playlist_items, older.playlist_items)
      if diff.any_changes?
        result = {
          start_date: older.created_at,
          end_date:   newer.created_at,
          removed:    diff.removed_songs.map(&:title),
          added:      diff.added_songs.map(&:title),
        }
        results << result
      end
    end

    {
      name:    playlist.name,
      changes: results,
    }
  end
end
