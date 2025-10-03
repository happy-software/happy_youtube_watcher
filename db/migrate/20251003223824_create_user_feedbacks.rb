class CreateUserFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :user_feedbacks do |t|
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
