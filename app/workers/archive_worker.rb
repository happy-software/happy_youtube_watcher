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

    unless response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection) # redirect to saved url is expected
      Honeybadger.context(
        {
          url:               url,
          playlist_delta_id: playlist_delta_id,
          response_body:     response.body,
        }
      )
      Honeybadger.notify("Wayback archive submission failed for #{url} with status #{response.code}")
    end
  end
end
