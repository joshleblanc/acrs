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

ActiveRecord::Schema[8.1].define(version: 2026_05_10_135622) do
  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "group_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.integer "player_id", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_assignments_on_group_id"
    t.index ["player_id"], name: "index_group_assignments_on_player_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "league_id", null: false
    t.integer "max_players"
    t.integer "min_players"
    t.string "name"
    t.integer "tier"
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_groups_on_league_id"
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "league_id", null: false
    t.integer "max_signups"
    t.string "token"
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_invites_on_league_id"
    t.index ["token"], name: "index_invites_on_token"
  end

  create_table "leagues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "game_id", null: false
    t.integer "match_day"
    t.string "name"
    t.string "slug"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_leagues_on_game_id"
  end

  create_table "maps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_maps_on_game_id"
  end

  create_table "match_games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_number"
    t.integer "map_id"
    t.integer "match_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.index ["map_id"], name: "index_match_games_on_map_id"
    t.index ["match_id"], name: "index_match_games_on_match_id"
    t.index ["winner_id"], name: "index_match_games_on_winner_id"
  end

  create_table "match_players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "match_id", null: false
    t.integer "player_id", null: false
    t.string "race"
    t.integer "race_id"
    t.boolean "ready"
    t.integer "score"
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_match_players_on_match_id"
    t.index ["player_id"], name: "index_match_players_on_player_id"
    t.index ["race_id"], name: "index_match_players_on_race_id"
  end

  create_table "matches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "league_id", null: false
    t.datetime "scheduled_at"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_matches_on_league_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "elo"
    t.integer "league_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["league_id"], name: "index_players_on_league_id"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "races", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_races_on_game_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "group_assignments", "groups"
  add_foreign_key "group_assignments", "players"
  add_foreign_key "groups", "leagues"
  add_foreign_key "invites", "leagues"
  add_foreign_key "leagues", "games"
  add_foreign_key "maps", "games"
  add_foreign_key "match_games", "maps"
  add_foreign_key "match_games", "matches"
  add_foreign_key "match_games", "players", column: "winner_id"
  add_foreign_key "match_players", "matches"
  add_foreign_key "match_players", "players"
  add_foreign_key "match_players", "races"
  add_foreign_key "matches", "leagues"
  add_foreign_key "players", "leagues"
  add_foreign_key "players", "users"
  add_foreign_key "races", "games"
  add_foreign_key "sessions", "users"
end
