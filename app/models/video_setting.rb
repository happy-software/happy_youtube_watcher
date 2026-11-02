class VideoSetting < ApplicationRecord
  belongs_to :user

  enum :setting_type, { start_stop_times: 0 }, validate: true

  validates :video_id, presence: true
  validates :setting_type, uniqueness: { scope: [:user_id, :video_id] }
  validate  :start_stop_times_are_valid, if: :start_stop_times?

  # start/end are stored as whole seconds, e.g. { "start" => 30, "end" => 4560 }
  def start_seconds = settings["start"]
  def end_seconds   = settings["end"]

  private

  def start_stop_times_are_valid
    unless start_seconds.is_a?(Integer) && start_seconds >= 0
      errors.add(:settings, "start must be a whole number of seconds, 0 or more")
    end

    unless end_seconds.is_a?(Integer) && end_seconds > 0
      errors.add(:settings, "end must be a whole number of seconds, more than 0")
    end

    if errors.none? && start_seconds >= end_seconds
      errors.add(:settings, "start must be before end")
    end
  end
end
