FactoryBot.define do
  factory :favorite_playlist do
    association :user
    association :tracked_playlist
  end
end
