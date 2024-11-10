class TrackedPlaylist < ApplicationRecord
  validates_presence_of :playlist_id
  validates :playlist_id, length: {minimum: 2, message: "Playlist ID isn't long enough. Are you sure it's a valid ID?"}
  validates :playlist_id, uniqueness: {message: "This playlist is already being tracked."}

  has_many :playlist_snapshots, foreign_key: :playlist_id, primary_key: :playlist_id
  has_many :playlist_deltas

  def self.get_history(playlist_id, page)
    playlist = find_by_playlist_id(playlist_id)
    # results = []
    # playlist.playlist_snapshots.find_each(batch_size: 1).each_cons(2) do |p|
    #   older, newer = p
    #   diff = PlaylistDifferenceCalculator.calculate_diffs(newer.playlist_items, older.playlist_items)
    #   if diff.any_changes?
    #     result = {
    #       start_date: older.created_at,
    #       end_date:   newer.created_at,
    #       removed:    diff.removed_songs.map(&:title),
    #       added:      diff.added_songs.map(&:title),
    #     }
    #     results << result
    #   end
    # end

    # results = playlist.playlist_deltas.includes(:playlist_snapshot).map do |delta|
    #   snapshot = delta.playlist_snapshot
    #   {
    #     start_date: snapshot.created_at,
    #     end_date:   snapshot.created_at,
    #     removed:    delta.removed.map { |d| d["title"] },
    #     added:      delta.added.map { |d| d["title"] },
    #   }
    # end
    deltas = playlist.playlist_deltas
                     .joins(:playlist_snapshot)
                     .select('playlist_delta.*, playlist_snapshots.created_at')
                     .order('playlist_snapshots.created_at DESC')
                     .page(page)
                     .per(50)

    # # Preprocess added and removed data to make rendering faster
    # deltas = deltas.map do |delta|
    #   {
    #     created_at: delta.playlist_snapshot.created_at,
    #     added:      delta.added.map { |song| song["title"] },
    #     removed:    delta.removed.map { |song| song["title"] }
    #   }
    # end

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
