FactoryBot.define do
  factory :video_setting do
    user
    sequence(:video_id) { |n| "video#{n}" }
    setting_type { :start_stop_times }
    settings { { "start" => 30, "end" => 120 } }
  end
end
