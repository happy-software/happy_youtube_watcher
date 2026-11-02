require 'rails_helper'

RSpec.describe VideoSetting, type: :model do
  describe 'validations' do
    it 'is valid with a start before the end' do
      expect(build(:video_setting)).to be_valid
    end

    it 'allows a start of 0' do
      expect(build(:video_setting, settings: { "start" => 0, "end" => 60 })).to be_valid
    end

    it 'requires a video_id' do
      expect(build(:video_setting, video_id: nil)).not_to be_valid
    end

    it 'rejects an unknown setting_type' do
      setting = build(:video_setting, setting_type: 'bogus')
      expect(setting).not_to be_valid
      expect(setting.errors[:setting_type]).to be_present
    end

    it 'rejects a start that is not before the end' do
      setting = build(:video_setting, settings: { "start" => 60, "end" => 60 })
      expect(setting).not_to be_valid
      expect(setting.errors[:settings]).to include("start must be before end")
    end

    it 'rejects missing or negative times' do
      expect(build(:video_setting, settings: { "end" => 60 })).not_to be_valid
      expect(build(:video_setting, settings: { "start" => -1, "end" => 60 })).not_to be_valid
      expect(build(:video_setting, settings: { "start" => 0 })).not_to be_valid
    end

    it 'allows only one setting of each type per user and video' do
      existing = create(:video_setting)
      duplicate = build(:video_setting, user: existing.user, video_id: existing.video_id)
      expect(duplicate).not_to be_valid
      expect(build(:video_setting, video_id: existing.video_id)).to be_valid # different user
    end
  end
end
