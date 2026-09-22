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

ActiveRecord::Schema[8.1].define(version: 2026_09_22_093634) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "applications", force: :cascade do |t|
    t.datetime "applied_at"
    t.integer "candidate_id", null: false
    t.text "cover_letter"
    t.datetime "created_at", null: false
    t.integer "job_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_applications_on_candidate_id"
    t.index ["job_id", "candidate_id"], name: "index_applications_on_job_id_and_candidate_id", unique: true
    t.index ["job_id"], name: "index_applications_on_job_id"
  end

  create_table "candidates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "experience_years"
    t.string "headline"
    t.string "resume_url"
    t.text "skills"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_candidates_on_user_id", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "location"
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "jobs", force: :cascade do |t|
    t.integer "category"
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.integer "currency", default: 0, null: false
    t.text "description"
    t.integer "job_type"
    t.string "location"
    t.datetime "posted_at"
    t.integer "recruiter_id", null: false
    t.integer "salary_max"
    t.integer "salary_min"
    t.integer "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_jobs_on_category"
    t.index ["company_id"], name: "index_jobs_on_company_id"
    t.index ["location"], name: "index_jobs_on_location"
    t.index ["recruiter_id"], name: "index_jobs_on_recruiter_id"
    t.index ["status"], name: "index_jobs_on_status"
    t.index ["title"], name: "index_jobs_on_title"
  end

  create_table "recruiters", force: :cascade do |t|
    t.integer "company_id", null: false
    t.datetime "created_at", null: false
    t.string "position"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["company_id"], name: "index_recruiters_on_company_id"
    t.index ["user_id"], name: "index_recruiters_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "applications", "candidates"
  add_foreign_key "applications", "jobs"
  add_foreign_key "candidates", "users"
  add_foreign_key "jobs", "companies"
  add_foreign_key "jobs", "recruiters"
  add_foreign_key "recruiters", "companies"
  add_foreign_key "recruiters", "users"
end
