module Youtube
  class EtagFetchError < StandardError; end
  class PlaylistEtagFetcher

    YT_API_BASE = "https://www.googleapis.com/youtube/v3/playlistItems".freeze

    attr_reader :playlist_id, :api_key
    def initialize(playlist_id)
      @playlist_id = playlist_id
      @api_key     = ENV.fetch("YT_API_KEY")
    end

    def fetch
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise QuotaExceededError.new("YouTube API quota exceeded!") if response.code == '403' && response.body.include?(QuotaExceededError::REASON)

        Honeybadger.context({
          response_code: response.code,
          response_body: response.body,
          playlist_id:   playlist_id,
        })
        raise EtagFetchError.new("Couldn't fetch playlist etag!")
      end

      JSON.parse(response.body).fetch("etag")
    end

    def uri
      URI("#{YT_API_BASE}?part=id&playlistId=#{playlist_id}&maxResults=1&key=#{api_key}")
    end
  end
end
