module SearchHelper
  # Playlists the user has favorited open their own page; anyone else's opens its public history
  def link_for_playlist(tracked_playlist)
    favorite_id = @favorite_ids_by_tracked_playlist[tracked_playlist.id]
    favorite_id ? favorite_playlist_path(favorite_id) : playlist_history_path(tracked_playlist.playlist_id)
  end

  # The part of a description around the first search word it contains, or nil if none of the words appear in it
  def description_excerpt(description, terms)
    return if description.blank?

    terms.lazy.filter_map { |term| excerpt(description.squish, term, radius: 80) }.first
  end

  # How many times any of the search words appear in the description, counted the same way `highlight` marks them
  def description_match_count(description, terms)
    return 0 if description.blank? || terms.empty?

    description.scan(Regexp.union(terms.map { |term| Regexp.new(Regexp.escape(term), Regexp::IGNORECASE) })).size
  end
end
