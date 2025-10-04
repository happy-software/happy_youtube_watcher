class AddEmailToUserFeedback < ActiveRecord::Migration[8.0]
  def change
    add_column :user_feedbacks, :email, :string
  end
end
