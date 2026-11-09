module Youtube
  # Adds up the YouTube API units spent inside a `track` block, per endpoint.
  # Every list request we make (playlistItems, videos) costs 1 unit, whatever page size we ask for.
  class QuotaUsage
    THREAD_KEY = :youtube_quota_usage

    attr_reader :units

    def self.track
      previous = Thread.current[THREAD_KEY]
      usage    = Thread.current[THREAD_KEY] = new
      yield usage
      usage
    ensure
      Thread.current[THREAD_KEY] = previous
    end

    # Does nothing outside a `track` block
    def self.record(endpoint, units = 1)
      Thread.current[THREAD_KEY]&.add(endpoint, units)
    end

    def initialize
      @units = Hash.new(0)
    end

    def add(endpoint, units)
      @units[endpoint] += units
    end

    def total
      @units.values.sum
    end

    def to_s
      breakdown = @units.map { |endpoint, units| "#{endpoint}: #{units}" }.join(', ')
      breakdown.empty? ? "#{total} units" : "#{total} units (#{breakdown})"
    end
  end
end
