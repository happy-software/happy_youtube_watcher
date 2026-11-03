module Youtube
  class VideoAvailabilityChecker
    REASON_KEY              = 'unavailable_reason'.freeze
    BATCH_SIZE              = 50 # Max number of ids the videos endpoint accepts per request
    REMOVED_UPLOAD_STATUSES = %w[deleted failed rejected].freeze

    # Takes playlist items keyed by video id and returns a copy where each unavailable video
    # has an 'unavailable_reason' of 'private', 'deleted' or 'region_blocked'.
    def self.annotate(playlist_items)
      videos = fetch_videos(playlist_items.keys)

      playlist_items.to_h do |video_id, song|
        reason = unavailable_reason(videos[video_id], song['title'])
        song   = song.except(REASON_KEY)
        song   = song.merge(REASON_KEY => reason) if reason
        [video_id, song]
      end
    end

    def self.fetch_videos(video_ids)
      video_ids.each_slice(BATCH_SIZE).each_with_object({}) do |ids, videos|
        Yt::Collections::Videos.new
                               .where(id: ids.join(','), part: 'status,contentDetails')
                               .each { |video| videos[video.id] = video }
      end
    end

    def self.unavailable_reason(video, title)
      if video.nil?
        # YouTube leaves out deleted videos and other people's private videos, so the title is the only hint
        title == 'Private video' ? 'private' : 'deleted'
      elsif video.status.data['privacyStatus'] == 'private'
        'private'
      elsif REMOVED_UPLOAD_STATUSES.include?(video.status.data['uploadStatus'])
        'deleted'
      elsif blocked_everywhere?(video.content_detail.data['regionRestriction'])
        'region_blocked'
      end
    end

    def self.blocked_everywhere?(region_restriction)
      return false if region_restriction.blank?

      allowed = region_restriction['allowed']
      blocked = region_restriction['blocked']

      # An empty allowed list means no country can watch it. An empty blocked list means every country can.
      return true if allowed && allowed.empty?
      return true if blocked && (CountryCodes::ALL - blocked).empty?

      false
    end
  end
end
