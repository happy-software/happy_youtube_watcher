# Fuzzy search across playlist names and the videos (title, channel, description) in each playlist's newest snapshot.
#
# Matching uses pg_trgm, so typos and partial words still match titles, channel names, and playlist names. Descriptions
# are long and noisy (often full lyrics), so they only match on the actual text. A video matches when the whole query is
# close to (or inside) one of its fields, or when every word of the query shows up somewhere in the video.
class PlaylistSearch
  MIN_QUERY_LENGTH = 2
  LIMIT            = 50
  # pg_trgm's default of 0.6 misses common typos, e.g. "micheal" vs "Michael" scores 0.5 and "goerge" vs "George" 0.43.
  # Going lower lets in more loose matches, but those rank below the close ones.
  FUZZY_THRESHOLD  = 0.4

  Results    = Data.define(:playlists, :videos)
  VideoMatch = Data.define(:video_id, :title, :channel_title, :description, :thumbnail_url, :tracked_playlists)

  def self.call(query, tracked_playlists:, limit: LIMIT)
    query = query.to_s.squish
    return Results.new(playlists: [], videos: []) if query.length < MIN_QUERY_LENGTH

    ActiveRecord::Base.transaction do
      # Sets the cutoff the `<%` operator uses, for this transaction only
      ActiveRecord::Base.connection.execute("SET LOCAL pg_trgm.word_similarity_threshold = #{FUZZY_THRESHOLD.to_f}")

      Results.new(
        playlists: matching_playlists(query, tracked_playlists, limit),
        videos:    matching_videos(query, tracked_playlists, limit),
      )
    end
  end

  def self.matching_playlists(query, tracked_playlists, limit)
    binds = { q: query, like: like(query) }

    tracked_playlists
      .where("tracked_playlists.name ILIKE :like OR :q <% tracked_playlists.name OR tracked_playlists.playlist_id = :q", binds)
      .reorder(Arel.sql(sanitize("word_similarity(:q, tracked_playlists.name) DESC, tracked_playlists.name", binds)))
      .limit(limit)
      .to_a
  end

  def self.matching_videos(query, tracked_playlists, limit)
    words = query.split.uniq.first(10)
    binds = { q: query, like: like(query) }
    words.each_with_index do |word, i|
      binds[:"word_#{i}"]      = word
      binds[:"word_like_#{i}"] = like(word)
    end

    # Each word can be misspelled on its own, e.g. "goerge micheal"
    every_word_matches = words.each_index.map do |i|
      "(:word_#{i} <% title OR :word_#{i} <% channel_title OR " \
        "title ILIKE :word_like_#{i} OR channel_title ILIKE :word_like_#{i} OR description ILIKE :word_like_#{i})"
    end.join(" AND ")

    # The exact query showing up in a field always beats a fuzzy-only match (title, then channel, then description).
    # Within each of those, the closer the title or channel is to the query, the higher it ranks.
    score = <<~SQL
      CASE
        WHEN title ILIKE :like         THEN 3.0
        WHEN channel_title ILIKE :like THEN 2.5
        WHEN description ILIKE :like   THEN 1.5
        ELSE 0
      END
      + GREATEST(word_similarity(:q, title), 0.9 * word_similarity(:q, channel_title), 0)
    SQL

    entries = VideoSearchEntry
      .where(tracked_playlist_id: tracked_playlists.select(:id))
      .where(<<~SQL, binds)
        video_id = :q
        OR title ILIKE :like OR channel_title ILIKE :like OR description ILIKE :like
        OR :q <% title OR :q <% channel_title
        OR (#{every_word_matches})
      SQL
      .select("video_search_entries.*", sanitize("#{score} AS score", binds))
      .order(Arel.sql("score DESC, title"))
      .limit(limit * 3) # The same video can be in several playlists, so grab extra before grouping
      .includes(:tracked_playlist)

    entries.group_by(&:video_id).first(limit).map do |video_id, rows|
      best = rows.first
      VideoMatch.new(
        video_id:          video_id,
        title:             best.title,
        channel_title:     best.channel_title,
        description:       best.description,
        thumbnail_url:     best.thumbnail_url,
        tracked_playlists: rows.map(&:tracked_playlist).uniq,
      )
    end
  end

  def self.like(text)
    "%#{ActiveRecord::Base.sanitize_sql_like(text)}%"
  end

  def self.sanitize(sql, binds)
    ActiveRecord::Base.sanitize_sql_array([sql, binds])
  end

  private_class_method :matching_playlists, :matching_videos, :like, :sanitize
end
