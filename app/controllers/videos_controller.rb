class VideosController < ApplicationController
  def index
    # Returns all videos across all tracked playlists
    # from their newest playlist snapshots
    raw_videos = TrackedPlaylist.all.map do |tp|
      tp.playlist_snapshots.newest&.playlist_items
    end.flatten.compact.uniq

    all_videos = raw_videos.map do |videos|
      videos.map do |video_id, video_info|
        {
          videoId:      video_id,
          title:        video_info['title'],
          playlistId:   video_info['playlistId'],
          playlistName: TrackedPlaylist.find_by_playlist_id(video_info['playlistId'])&.name,
          channelName:  video_info['channelTitle'],
          description:  video_info['description'],
        }
      end
    end.flatten

    json_response(all_videos)
  end
end
