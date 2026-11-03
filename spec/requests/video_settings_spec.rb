require 'rails_helper'

RSpec.describe "VideoSettings", type: :request do
  let(:user) { create(:user) }
  let(:params) { { video_setting: { setting_type: "start_stop_times", settings: { start: 30, end: 4560 } } } }

  describe "PUT /video-settings/:video_id" do
    it "requires a signed in user" do
      put "/video-settings/abc-123_XY", params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    context "when signed in" do
      before { sign_in user }

      it "creates the setting" do
        expect {
          put "/video-settings/abc-123_XY", params: params, as: :json
        }.to change(user.video_settings, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["settings"]).to eq("start" => 30, "end" => 4560)
        expect(user.video_settings.last).to have_attributes(video_id: "abc-123_XY", setting_type: "start_stop_times")
      end

      it "updates an existing setting instead of adding another" do
        create(:video_setting, user: user, video_id: "abc-123_XY")

        expect {
          put "/video-settings/abc-123_XY", params: params, as: :json
        }.not_to change(VideoSetting, :count)

        expect(user.video_settings.last.settings).to eq("start" => 30, "end" => 4560)
      end

      it "stores fractional seconds as whole seconds" do
        put "/video-settings/abc", params: { video_setting: { setting_type: "start_stop_times", settings: { start: 30.7, end: 90.2 } } }, as: :json
        expect(response.parsed_body["settings"]).to eq("start" => 30, "end" => 90)
      end

      it "rejects invalid times" do
        put "/video-settings/abc", params: { video_setting: { setting_type: "start_stop_times", settings: { start: 90, end: 30 } } }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to include("Settings start must be before end")
      end

      it "rejects an unknown setting type" do
        put "/video-settings/abc", params: { video_setting: { setting_type: "bogus", settings: { start: 0, end: 30 } } }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /video-settings/:video_id" do
    before { sign_in user }

    it "removes only the signed in user's setting" do
      mine   = create(:video_setting, user: user, video_id: "abc")
      theirs = create(:video_setting, video_id: "abc")

      delete "/video-settings/abc", params: { setting_type: "start_stop_times" }

      expect(response).to have_http_status(:no_content)
      expect(VideoSetting.exists?(mine.id)).to be false
      expect(VideoSetting.exists?(theirs.id)).to be true
    end

    it "succeeds when there is nothing to delete" do
      delete "/video-settings/abc", params: { setting_type: "start_stop_times" }
      expect(response).to have_http_status(:no_content)
    end
  end
end
