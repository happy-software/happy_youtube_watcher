FactoryBot.define do
  factory :playlist_snapshot do
    association :tracked_playlist
    playlist_id { tracked_playlist.playlist_id }
    playlist_items { {} }
    etag { SecureRandom.hex(8) }
  end
end
