class UserFeedback < ApplicationRecord
  class FeedbackMessageValidator < ActiveModel::Validator
    def validate(record)
      unless record.message.to_plain_text.length > 15
        record.errors.add :message, "must have at least 15 characters."
      end
    end
  end

  belongs_to :user

  has_rich_text :message

  validates :message, presence: true
  validates_with FeedbackMessageValidator

  after_create :notify_slack

  def notify_slack
    YoutubeWatcher::Slacker.post_message("New user feedback submitted by #{user.email}!", "#happy-alerts")
  end
end
