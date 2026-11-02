class VideoSettingsController < ApplicationController
  before_action :authenticate_user!

  # PUT /video-settings/:video_id
  def update
    video_setting = current_user.video_settings.find_or_initialize_by(video_id: params[:video_id], setting_type: video_setting_params[:setting_type])
    video_setting.settings = normalized_settings

    if video_setting.save
      ahoy.track "video_setting_saved", video_id: video_setting.video_id, setting_type: video_setting.setting_type, settings: video_setting.settings
      render json: video_setting.slice(:video_id, :setting_type, :settings)
    else
      render json: { errors: video_setting.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /video-settings/:video_id?setting_type=start_stop_times
  def destroy
    video_setting = current_user.video_settings.find_by(video_id: params[:video_id], setting_type: params.expect(:setting_type))
    video_setting&.destroy!
    ahoy.track "video_setting_reset", video_id: params[:video_id], setting_type: params[:setting_type]

    head :no_content
  end

  private

  def video_setting_params
    params.expect(video_setting: [:setting_type, settings: [:start, :end]])
  end

  # JSON bodies may send numbers as floats or strings; store whole seconds
  def normalized_settings
    video_setting_params.fetch(:settings, {}).to_h.transform_values { |v| Integer(v.to_s.split(".").first, exception: false) }
  end
end
