class CreateFavoritePlaylists < ActiveRecord::Migration[8.0]
  def change
    create_table :favorite_playlists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tracked_playlist, null: false, foreign_key: true

      t.timestamps
    end
  end
end
