# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_04_20_142137) do
  create_schema "_heroku"
  create_schema "heroku_ext"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "playlist_delta", force: :cascade do |t|
    t.bigint "tracked_playlist_id", null: false
    t.bigint "playlist_snapshot_id", null: false
    t.jsonb "added", default: {}, null: false
    t.jsonb "removed", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_snapshot_id"], name: "index_playlist_delta_on_playlist_snapshot_id"
    t.index ["tracked_playlist_id"], name: "index_playlist_delta_on_tracked_playlist_id"
  end

  create_table "playlist_items", id: false, force: :cascade do |t|
    t.integer "id", null: false
    t.integer "playlist_snapshot_id"
  end

  create_table "playlist_settings", force: :cascade do |t|
    t.string "playlist_id"
    t.jsonb "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "playlist_snapshots", force: :cascade do |t|
    t.string "playlist_id"
    t.jsonb "playlist_items"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["created_at"], name: "index_playlist_snapshots_on_created_at"
    t.index ["playlist_id"], name: "index_playlist_snapshots_on_playlist_id"
  end

  create_table "tracked_playlists", force: :cascade do |t|
    t.string "playlist_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_default"
    t.string "name"
    t.string "channel_id"
    t.boolean "active", default: true
    t.index ["channel_id"], name: "index_tracked_playlists_on_channel_id"
    t.index ["is_default"], name: "index_tracked_playlists_on_is_default"
    t.index ["name"], name: "index_tracked_playlists_on_name"
    t.index ["playlist_id"], name: "index_tracked_playlists_on_playlist_id", unique: true
  end

  add_foreign_key "playlist_delta", "playlist_snapshots"
  add_foreign_key "playlist_delta", "tracked_playlists"
end
