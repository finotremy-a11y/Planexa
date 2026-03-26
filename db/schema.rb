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

ActiveRecord::Schema[8.0].define(version: 2026_03_26_094128) do
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

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analytics_events", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "company_id"
    t.bigint "user_id"
    t.string "session_id"
    t.jsonb "properties", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["company_id"], name: "index_analytics_events_on_company_id"
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["name", "company_id"], name: "index_analytics_events_on_name_and_company_id"
    t.index ["name"], name: "index_analytics_events_on_name"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.string "token_digest", null: false
    t.datetime "last_used_at"
    t.datetime "expires_at"
    t.jsonb "scopes", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_api_tokens_on_company_id"
    t.index ["expires_at"], name: "index_api_tokens_on_expires_at"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
  end

  create_table "api_webhooks", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "url", null: false
    t.jsonb "events", default: [], null: false
    t.string "secret", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_api_webhooks_on_active"
    t.index ["company_id"], name: "index_api_webhooks_on_company_id"
  end

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
    t.bigint "booking_group_id"
    t.datetime "reconfirmation_requested_at"
    t.datetime "reconfirmed_at"
    t.index ["booking_group_id"], name: "index_appointments_on_booking_group_id"
    t.index ["client_user_id", "scheduled_at"], name: "index_appointments_on_client_user_id_and_scheduled_at"
    t.index ["client_user_id"], name: "index_appointments_on_client_user_id"
    t.index ["company_id", "scheduled_at"], name: "index_appointments_on_company_id_and_scheduled_at"
    t.index ["company_id"], name: "index_appointments_on_company_id"
    t.index ["employee_id", "scheduled_at"], name: "index_appointments_on_employee_id_and_scheduled_at"
    t.index ["employee_id"], name: "index_appointments_on_employee_id"
    t.index ["reconfirmation_requested_at"], name: "index_appointments_on_reconfirmation_requested_at"
    t.index ["reconfirmed_at"], name: "index_appointments_on_reconfirmed_at"
    t.index ["service_type_id"], name: "index_appointments_on_service_type_id"
    t.index ["status"], name: "index_appointments_on_status"
    t.index ["urgent"], name: "index_appointments_on_urgent"
  end

  create_table "booking_groups", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "client_user_id"
    t.integer "total_amount_cents", default: 0, null: false
    t.string "currency", default: "EUR", null: false
    t.integer "status", default: 0, null: false
    t.text "client_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_user_id"], name: "index_booking_groups_on_client_user_id"
    t.index ["company_id"], name: "index_booking_groups_on_company_id"
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
    t.string "widget_token", null: false
    t.integer "professional_category", default: 0, null: false
    t.string "health_specialty"
    t.string "convention_sector"
    t.boolean "teleconsultation_enabled", default: false, null: false
    t.text "accessibility_info"
    t.text "practical_info"
    t.text "cancellation_policy"
    t.index ["name"], name: "index_companies_on_name"
    t.index ["professional_category"], name: "index_companies_on_professional_category"
    t.index ["siret"], name: "index_companies_on_siret", unique: true
    t.index ["status"], name: "index_companies_on_status"
    t.index ["user_id"], name: "index_companies_on_user_id"
    t.index ["widget_token"], name: "index_companies_on_widget_token", unique: true
  end

  create_table "company_closures", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "reason"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "starts_at", "ends_at"], name: "index_company_closures_on_company_and_range"
    t.index ["company_id"], name: "index_company_closures_on_company_id"
  end

  create_table "company_settings", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.integer "booking_mode", default: 0, null: false
    t.integer "payment_mode", default: 1, null: false
    t.integer "assignment_mode", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "sms_reminders_enabled", default: false, null: false
    t.boolean "loyalty_enabled", default: false, null: false
    t.integer "points_per_appointment", default: 10, null: false
    t.integer "loyalty_points_threshold", default: 100, null: false
    t.integer "loyalty_discount_value_cents", default: 1000, null: false
    t.boolean "email_reminders_enabled", default: true, null: false
    t.boolean "push_reminders_enabled", default: false, null: false
    t.integer "slot_interval_minutes", default: 15, null: false
    t.integer "buffer_between_appointments_minutes", default: 0, null: false
    t.boolean "allow_controlled_overbooking", default: false, null: false
    t.integer "overbooking_limit_per_slot", default: 0, null: false
    t.integer "emergency_daily_capacity", default: 0, null: false
    t.index ["company_id"], name: "index_company_settings_on_company_id", unique: true
  end

  create_table "discount_codes", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "client_user_id", null: false
    t.string "code", null: false
    t.integer "discount_type", default: 0, null: false
    t.integer "discount_value_cents", default: 0, null: false
    t.datetime "used_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_user_id", "company_id"], name: "index_discount_codes_on_client_user_id_and_company_id"
    t.index ["client_user_id"], name: "index_discount_codes_on_client_user_id"
    t.index ["code"], name: "index_discount_codes_on_code", unique: true
    t.index ["company_id"], name: "index_discount_codes_on_company_id"
  end

  create_table "employee_absences", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "reason", default: "other", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "starts_at", "ends_at"], name: "index_employee_absences_on_employee_and_range"
    t.index ["employee_id"], name: "index_employee_absences_on_employee_id"
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

  create_table "invoices", force: :cascade do |t|
    t.bigint "payment_id", null: false
    t.bigint "company_id", null: false
    t.bigint "client_user_id"
    t.string "invoice_number", null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.decimal "tax_rate", precision: 5, scale: 4, default: "0.2", null: false
    t.integer "tax_amount_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.string "currency", default: "EUR", null: false
    t.datetime "issued_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_user_id"], name: "index_invoices_on_client_user_id"
    t.index ["company_id", "issued_at"], name: "index_invoices_on_company_id_and_issued_at"
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["payment_id"], name: "index_invoices_on_payment_id", unique: true
  end

  create_table "loyalty_points", force: :cascade do |t|
    t.bigint "client_user_id", null: false
    t.bigint "company_id", null: false
    t.bigint "appointment_id"
    t.integer "points", null: false
    t.string "reason", default: "earned", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_loyalty_points_on_appointment_id"
    t.index ["client_user_id", "company_id"], name: "index_loyalty_points_on_client_user_id_and_company_id"
    t.index ["client_user_id"], name: "index_loyalty_points_on_client_user_id"
    t.index ["company_id"], name: "index_loyalty_points_on_company_id"
  end

  create_table "medical_audit_logs", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "user_id"
    t.string "action", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_medical_audit_logs_on_action"
    t.index ["company_id", "created_at"], name: "index_medical_audit_logs_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_medical_audit_logs_on_company_id"
    t.index ["record_type", "record_id"], name: "index_medical_audit_logs_on_record_type_and_record_id"
    t.index ["user_id"], name: "index_medical_audit_logs_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.integer "kind", default: 0, null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "created_at"], name: "index_notifications_on_company_id_and_created_at"
    t.index ["company_id", "read_at"], name: "index_notifications_on_company_id_and_read_at"
    t.index ["company_id"], name: "index_notifications_on_company_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
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

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "company_id", null: false
    t.string "endpoint", null: false
    t.string "auth", null: false
    t.string "p256dh", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_push_subscriptions_on_company_id"
    t.index ["user_id", "company_id", "endpoint"], name: "idx_push_sub_unique", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "reminder_deliveries", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "appointment_id", null: false
    t.integer "channel", null: false
    t.integer "status", null: false
    t.datetime "delivered_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id", "channel"], name: "index_reminder_deliveries_on_appointment_id_and_channel"
    t.index ["appointment_id"], name: "index_reminder_deliveries_on_appointment_id"
    t.index ["company_id", "created_at"], name: "index_reminder_deliveries_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_reminder_deliveries_on_company_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.bigint "client_user_id", null: false
    t.bigint "company_id", null: false
    t.integer "rating"
    t.text "comment"
    t.string "token", null: false
    t.datetime "submitted_at"
    t.datetime "published_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_reviews_on_appointment_id"
    t.index ["appointment_id"], name: "index_reviews_on_appointment_id_unique", unique: true
    t.index ["client_user_id"], name: "index_reviews_on_client_user_id"
    t.index ["company_id"], name: "index_reviews_on_company_id"
    t.index ["published_at"], name: "index_reviews_on_published_at"
    t.index ["token"], name: "index_reviews_on_token", unique: true
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
    t.integer "deposit_kind", default: 0, null: false
    t.integer "deposit_value", default: 0, null: false
    t.index ["active"], name: "index_service_types_on_active"
    t.index ["company_id", "name"], name: "index_service_types_on_company_id_and_name"
    t.index ["company_id"], name: "index_service_types_on_company_id"
    t.index ["deposit_kind"], name: "index_service_types_on_deposit_kind"
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
    t.boolean "sms_opt_out", default: false, null: false
    t.string "locale", default: "fr", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["locale"], name: "index_users_on_locale"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "waitlist_entries", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "service_type_id", null: false
    t.bigint "client_user_id"
    t.string "client_email"
    t.string "client_name"
    t.date "preferred_date"
    t.string "token", null: false
    t.datetime "notified_at"
    t.datetime "expired_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_user_id"], name: "index_waitlist_entries_on_client_user_id"
    t.index ["company_id", "service_type_id", "created_at"], name: "index_waitlist_on_company_service_created"
    t.index ["company_id"], name: "index_waitlist_entries_on_company_id"
    t.index ["expired_at"], name: "index_waitlist_entries_on_expired_at"
    t.index ["notified_at"], name: "index_waitlist_entries_on_notified_at"
    t.index ["service_type_id"], name: "index_waitlist_entries_on_service_type_id"
    t.index ["token"], name: "index_waitlist_entries_on_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "companies"
  add_foreign_key "api_webhooks", "companies"
  add_foreign_key "appointments", "booking_groups"
  add_foreign_key "appointments", "companies"
  add_foreign_key "appointments", "employees"
  add_foreign_key "appointments", "service_types"
  add_foreign_key "appointments", "users", column: "client_user_id"
  add_foreign_key "booking_groups", "companies"
  add_foreign_key "booking_groups", "users", column: "client_user_id"
  add_foreign_key "companies", "users"
  add_foreign_key "company_closures", "companies"
  add_foreign_key "company_settings", "companies"
  add_foreign_key "discount_codes", "companies"
  add_foreign_key "discount_codes", "users", column: "client_user_id"
  add_foreign_key "employee_absences", "employees"
  add_foreign_key "employee_skills", "employees"
  add_foreign_key "employee_skills", "service_types"
  add_foreign_key "employees", "companies"
  add_foreign_key "invoices", "companies"
  add_foreign_key "invoices", "payments"
  add_foreign_key "invoices", "users", column: "client_user_id"
  add_foreign_key "loyalty_points", "appointments"
  add_foreign_key "loyalty_points", "companies"
  add_foreign_key "loyalty_points", "users", column: "client_user_id"
  add_foreign_key "medical_audit_logs", "companies"
  add_foreign_key "medical_audit_logs", "users"
  add_foreign_key "notifications", "companies"
  add_foreign_key "payments", "appointments"
  add_foreign_key "payments", "companies"
  add_foreign_key "payments", "users", column: "client_user_id"
  add_foreign_key "push_subscriptions", "companies"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "reminder_deliveries", "appointments"
  add_foreign_key "reminder_deliveries", "companies"
  add_foreign_key "reviews", "appointments"
  add_foreign_key "reviews", "companies"
  add_foreign_key "reviews", "users", column: "client_user_id"
  add_foreign_key "schedules", "companies"
  add_foreign_key "schedules", "employees"
  add_foreign_key "service_types", "companies"
  add_foreign_key "subscriptions", "companies"
  add_foreign_key "waitlist_entries", "companies"
  add_foreign_key "waitlist_entries", "service_types"
  add_foreign_key "waitlist_entries", "users", column: "client_user_id"
end
