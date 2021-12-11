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

ActiveRecord::Schema.define(version: 2021_06_11_014548) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "playlist_settings", force: :cascade do |t|
    t.string "playlist_id"
    t.jsonb "settings"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "playlist_snapshots", force: :cascade do |t|
    t.string "playlist_id"
    t.jsonb "playlist_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id"], name: "index_playlist_snapshots_on_playlist_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.string "channel_username"
    t.string "channel_id"
    t.string "youtube_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["youtube_id"], name: "index_playlists_on_youtube_id", unique: true
  end

  create_table "songs", force: :cascade do |t|
    t.string "video_id"
    t.string "title"
    t.string "uploader"
    t.datetime "video_uploaded_date"
    t.jsonb "description"
    t.string "playlist_id"
    t.string "playlist_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tracked_playlists", force: :cascade do |t|
    t.string "playlist_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_default"
    t.string "name"
    t.string "channel_id"
    t.index ["channel_id"], name: "index_tracked_playlists_on_channel_id"
    t.index ["is_default"], name: "index_tracked_playlists_on_is_default"
    t.index ["name"], name: "index_tracked_playlists_on_name"
    t.index ["playlist_id"], name: "index_tracked_playlists_on_playlist_id", unique: true
  end

end
