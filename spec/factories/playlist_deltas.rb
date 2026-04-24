FactoryBot.define do
  factory :playlist_delta do
    association :tracked_playlist
    association :playlist_snapshot
    added { [] }
    removed { [] }
  end
end
