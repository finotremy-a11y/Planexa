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

ActiveRecord::Schema[8.0].define(version: 2026_03_13_114947) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  enable_extension "graphql.pg_graphql"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "unaccent"
  enable_extension "vault.supabase_vault"

  create_table "appointments", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "service_type_id", null: false
    t.bigint "client_user_id"
    t.bigint "employee_id"
    t.datetime "scheduled_at", null: false
    t.integer "duration_minutes", null: false
    t.integer "status", default: 0, null: false
    t.integer "booking_source", default: 0
    t.boolean "urgent", default: false
    t.text "client_notes"
    t.text "internal_notes"
    t.string "cancellation_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_user_id", "scheduled_at"], name: "index_appointments_on_client_user_id_and_scheduled_at"
    t.index ["client_user_id"], name: "index_appointments_on_client_user_id"
    t.index ["company_id", "scheduled_at"], name: "index_appointments_on_company_id_and_scheduled_at"
    t.index ["company_id"], name: "index_appointments_on_company_id"
    t.index ["employee_id", "scheduled_at"], name: "index_appointments_on_employee_id_and_scheduled_at"
    t.index ["employee_id"], name: "index_appointments_on_employee_id"
    t.index ["service_type_id"], name: "index_appointments_on_service_type_id"
    t.index ["status"], name: "index_appointments_on_status"
    t.index ["urgent"], name: "index_appointments_on_urgent"
  end

  create_table "companies", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "siret", null: false
    t.string "address", null: false
    t.string "city", null: false
    t.string "zip_code", null: false
    t.string "phone"
    t.text "description"
    t.string "website"
    t.string "logo_public_id"
    t.string "stripe_account_id"
    t.string "stripe_customer_id"
    t.boolean "stripe_onboarding_complete", default: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name"
    t.index ["siret"], name: "index_companies_on_siret", unique: true
    t.index ["status"], name: "index_companies_on_status"
    t.index ["user_id"], name: "index_companies_on_user_id"
  end

  create_table "company_settings", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.integer "booking_mode", default: 0, null: false
    t.integer "payment_mode", default: 1, null: false
    t.integer "assignment_mode", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_settings_on_company_id", unique: true
  end

  create_table "employee_skills", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "service_type_id", null: false
    t.integer "level", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "service_type_id"], name: "index_employee_skills_on_employee_id_and_service_type_id", unique: true
    t.index ["employee_id"], name: "index_employee_skills_on_employee_id"
    t.index ["service_type_id"], name: "index_employee_skills_on_service_type_id"
  end

  create_table "employees", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone"
    t.string "photo_public_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "active"], name: "index_employees_on_company_id_and_active"
    t.index ["company_id"], name: "index_employees_on_company_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.bigint "client_user_id", null: false
    t.bigint "company_id", null: false
    t.string "stripe_payment_intent_id", null: false
    t.string "stripe_transfer_id"
    t.integer "amount_cents", null: false
    t.string "currency", default: "eur", null: false
    t.integer "status", default: 0, null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_payments_on_appointment_id", unique: true
    t.index ["client_user_id"], name: "index_payments_on_client_user_id"
    t.index ["company_id"], name: "index_payments_on_company_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["stripe_payment_intent_id"], name: "index_payments_on_stripe_payment_intent_id", unique: true
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "company_id", null: false
    t.integer "day_of_week"
    t.time "start_time"
    t.time "end_time"
    t.date "specific_date"
    t.boolean "available", default: true
    t.string "schedule_type", default: "recurring"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_schedules_on_company_id"
    t.index ["employee_id", "day_of_week"], name: "index_schedules_on_employee_id_and_day_of_week"
    t.index ["employee_id", "specific_date"], name: "index_schedules_on_employee_id_and_specific_date"
    t.index ["employee_id"], name: "index_schedules_on_employee_id"
  end

  create_table "service_types", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "duration_minutes", default: 60, null: false
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "EUR", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_service_types_on_active"
    t.index ["company_id", "name"], name: "index_service_types_on_company_id_and_name"
    t.index ["company_id"], name: "index_service_types_on_company_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "stripe_subscription_id", null: false
    t.string "stripe_price_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "trial_ends_at"
    t.datetime "current_period_end"
    t.datetime "suspended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_subscriptions_on_company_id", unique: true
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.string "phone"
    t.integer "role", default: 0, null: false
    t.string "stripe_customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "appointments", "companies"
  add_foreign_key "appointments", "employees"
  add_foreign_key "appointments", "service_types"
  add_foreign_key "appointments", "users", column: "client_user_id"
  add_foreign_key "companies", "users"
  add_foreign_key "company_settings", "companies"
  add_foreign_key "employee_skills", "employees"
  add_foreign_key "employee_skills", "service_types"
  add_foreign_key "employees", "companies"
  add_foreign_key "payments", "appointments"
  add_foreign_key "payments", "companies"
  add_foreign_key "payments", "users", column: "client_user_id"
  add_foreign_key "schedules", "companies"
  add_foreign_key "schedules", "employees"
  add_foreign_key "service_types", "companies"
  add_foreign_key "subscriptions", "companies"
end
