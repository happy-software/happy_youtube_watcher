FactoryBot.define do
  factory :tracked_playlist do
    sequence(:playlist_id) { |n| "PLtest#{n}abcdefgh" }
    name { "Test Playlist" }
    active { true }
  end
end
