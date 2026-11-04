module PlaylistItemsHelper
  # Builds the playlist_items hash a snapshot stores, keyed by video id, e.g.
  #   playlist_items("abc" => { title: "Song", channel: "Artist", description: "Lyrics" })
  def playlist_items(videos)
    videos.each_with_index.to_h do |(video_id, video), position|
      [video_id, {
        'title'                  => video[:title],
        'position'               => position,
        'resourceId'             => { 'kind' => 'youtube#video', 'videoId' => video_id },
        'thumbnails'             => { 'medium' => { 'url' => "https://i.ytimg.com/vi/#{video_id}/mqdefault.jpg" } },
        'description'            => video[:description].to_s,
        'channelTitle'           => 'Playlist Owner',
        'videoOwnerChannelTitle' => video[:channel],
      }.merge(video.fetch(:extra, {}))]
    end
  end
end

RSpec.configure do |config|
  config.include PlaylistItemsHelper
end
