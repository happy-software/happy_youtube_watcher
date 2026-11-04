class CreateVideoSearchEntries < ActiveRecord::Migration[8.1]
  def up
    # Trigram matching powers the fuzzy search. Creating it needs a superuser on Postgres < 13.
    enable_extension "pg_trgm"

    # One row per video in the newest snapshot of each tracked playlist, so search doesn't have to unpack the
    # playlist_items json on every query.
    create_table :video_search_entries do |t|
      t.references :tracked_playlist, null: false, foreign_key: true, index: false
      t.string :video_id, null: false
      t.string :title
      t.string :channel_title
      t.text :description
      t.string :thumbnail_url
      t.integer :position
      t.timestamps
    end

    add_index :video_search_entries, [:tracked_playlist_id, :video_id], unique: true
    add_index :video_search_entries, :video_id
    add_index :video_search_entries, :title,         using: :gin, opclass: :gin_trgm_ops, name: "index_video_search_entries_on_title_trgm"
    add_index :video_search_entries, :channel_title, using: :gin, opclass: :gin_trgm_ops, name: "index_video_search_entries_on_channel_title_trgm"
    add_index :video_search_entries, :description,   using: :gin, opclass: :gin_trgm_ops, name: "index_video_search_entries_on_description_trgm"
    add_index :tracked_playlists,    :name,          using: :gin, opclass: :gin_trgm_ops, name: "index_tracked_playlists_on_name_trgm"

    # Backfill from the newest snapshot of every tracked playlist
    VideoSearchEntry.reset_column_information
    VideoSearchEntry.rebuild_from(PlaylistSnapshot.newest_per_playlist)
  end

  def down
    remove_index :tracked_playlists, name: "index_tracked_playlists_on_name_trgm"
    drop_table :video_search_entries
    # pg_trgm is left enabled; dropping it could break anything else that started relying on it.
  end
end
