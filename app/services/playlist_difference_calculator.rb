class PlaylistDifferenceCalculator
  def self.calculate_diffs(current_songs, previous_songs)
    removed = previous_songs.reject { |k,_v| current_songs.key?(k) }.values.map(&:with_indifferent_access)
    added   = current_songs.reject  { |k,_v| previous_songs.key?(k) }.values.map(&:with_indifferent_access)

    diffs = { removed: removed, added: added}
    new(diffs)
  end

  def initialize(diffs)
    @diffs = diffs
  end

  def any_changes?
    @diffs[:removed].any? || @diffs[:added].any?
  end

  def removed_songs
    @removed_songs ||= @diffs[:removed].map { |song_details| create_song(song_details) }
  end

  def added_songs
    @added_songs ||= @diffs[:added].map { |song_details| create_song(song_details) }
  end

  private

  Song = Struct.new(:position, :title, :url, keyword_init: true)

  def create_song(song_details)
    position = song_details[:position]
    title = song_details[:title]
    url = "https://youtube.com/watch?v=#{song_details.dig(:resourceId, :videoId)}"
    Song.new(position: position, title: title, url: url)
  end
end
