class CreateVideoSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :video_settings do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :video_id, null: false
      t.integer :setting_type, null: false
      t.jsonb :settings, default: {}, null: false
      t.timestamps
    end

    # Covers lookups by user as well as user + video, and guarantees one row per setting type
    add_index :video_settings, [:user_id, :video_id, :setting_type], unique: true, name: "index_video_settings_on_user_video_type"
  end
end
