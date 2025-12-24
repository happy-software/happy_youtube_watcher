class ArchiveWorker
  include Sidekiq::Worker

  def self.archive_videos(playlist_delta)
    playlist_delta.added.each do |video|
      v = video.with_indifferent_access
      perform_async(v.fetch(:url), playlist_delta.id)
    end
  end

  def perform(url, playlist_delta_id)
    encoded_url  = URI.encode_www_form_component(url)
    archive_api  = "https://web.archive.org/save/#{encoded_url}"
    uri          = URI(archive_api)
    http         = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request  = Net::HTTP::Get.new(uri)
    response = http.request(request)

    # TODO: Figure out something about 429s when there are a bunch of new videos added and triggering workers all at the same time
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    # do nothing, best effort attempts only here
  end
end
