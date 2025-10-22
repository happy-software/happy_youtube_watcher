class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :favorite_playlists

  has_many :ahoy_visits, :class_name => 'Ahoy::Visit'
  has_many :ahoy_events, :class_name => 'Ahoy::Event'

  after_create :notify_slack

  def notify_slack
    YoutubeWatcher::Slacker.post_message("New user (#{self.email}) joined!", "#happy-alerts")
  end
end
