class CreatePlaylistDelta < ActiveRecord::Migration[6.1]
  def change
    create_table :playlist_delta do |t|
      t.references :tracked_playlist, null: false, foreign_key: true, index: true
      t.references :playlist_snapshot, null: false, foreign_key: true, index: true
      t.jsonb :added, default: {}, null: false
      t.jsonb :removed, default: {}, null: false

      t.timestamps
    end
  end
end
