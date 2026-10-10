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

ActiveRecord::Schema[8.1].define(version: 2026_10_09_160000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "city"
    t.string "complement"
    t.string "country", default: "Brasil"
    t.datetime "created_at", null: false
    t.bigint "establishment_id", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "neighborhood"
    t.string "number"
    t.string "state"
    t.string "street"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["establishment_id"], name: "index_addresses_on_establishment_id", unique: true
  end

  create_table "appointment_feedbacks", force: :cascade do |t|
    t.boolean "anonymous", default: true, null: false
    t.bigint "appointment_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.integer "rating", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_appointment_feedbacks_on_appointment_id", unique: true
    t.index ["customer_id"], name: "index_appointment_feedbacks_on_customer_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.date "appointment_date", null: false
    t.datetime "canceled_at"
    t.text "cancellation_reason"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.string "customer_name_snapshot"
    t.integer "duration_minutes"
    t.bigint "employee_id", null: false
    t.string "employee_name_snapshot"
    t.time "end_time", null: false
    t.bigint "establishment_id", null: false
    t.text "notes"
    t.decimal "price_snapshot", precision: 10, scale: 2
    t.bigint "service_id", null: false
    t.string "service_name_snapshot"
    t.integer "service_package_id"
    t.time "start_time", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_date"], name: "index_appointments_on_appointment_date"
    t.index ["customer_id"], name: "index_appointments_on_customer_id"
    t.index ["employee_id", "appointment_date", "start_time"], name: "idx_appointments_on_employee_date_time_unique", unique: true, where: "((status)::text <> 'canceled'::text)"
    t.index ["employee_id"], name: "index_appointments_on_employee_id"
    t.index ["establishment_id"], name: "index_appointments_on_establishment_id"
    t.index ["service_id"], name: "index_appointments_on_service_id"
    t.index ["status"], name: "index_appointments_on_status"
  end

  create_table "archived_employees", force: :cascade do |t|
    t.datetime "archived_at", null: false
    t.bigint "archived_by_id"
    t.datetime "created_at", null: false
    t.bigint "establishment_id", null: false
    t.jsonb "membership_data", default: {}, null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.jsonb "user_data", default: {}, null: false
    t.bigint "user_id", null: false
    t.index ["archived_by_id"], name: "index_archived_employees_on_archived_by_id"
    t.index ["establishment_id"], name: "index_archived_employees_on_establishment_id"
    t.index ["user_id"], name: "index_archived_employees_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}
    t.bigint "establishment_id"
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["establishment_id"], name: "index_audit_logs_on_establishment_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "business_hours", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.time "end_time"
    t.bigint "establishment_id", null: false
    t.boolean "is_open", default: true
    t.time "start_time"
    t.datetime "updated_at", null: false
    t.integer "weekday", null: false
    t.index ["establishment_id", "weekday"], name: "index_business_hours_on_establishment_and_weekday", unique: true
    t.index ["establishment_id"], name: "index_business_hours_on_establishment_id"
  end

  create_table "commission_closing_histories", force: :cascade do |t|
    t.string "action", null: false
    t.jsonb "changes_snapshot", default: {}
    t.bigint "commission_closing_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["commission_closing_id"], name: "index_commission_closing_histories_on_commission_closing_id"
    t.index ["user_id"], name: "index_commission_closing_histories_on_user_id"
  end

  create_table "commission_closing_items", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.decimal "commission_amount", precision: 10, scale: 2, null: false
    t.bigint "commission_closing_id", null: false
    t.bigint "commission_id", null: false
    t.string "commission_rule_applied"
    t.datetime "created_at", null: false
    t.decimal "service_amount", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_commission_closing_items_on_appointment_id"
    t.index ["commission_closing_id"], name: "index_commission_closing_items_on_commission_closing_id"
    t.index ["commission_id"], name: "index_commission_closing_items_on_commission_id"
  end

  create_table "commission_closings", force: :cascade do |t|
    t.datetime "closed_at"
    t.bigint "closed_by_id"
    t.decimal "commission_bonus_snapshot", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.bigint "establishment_id", null: false
    t.string "financial_model_snapshot"
    t.decimal "financial_value_snapshot", precision: 10, scale: 2
    t.decimal "gross_commission_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "gross_revenue", precision: 10, scale: 2, default: "0.0"
    t.bigint "membership_id"
    t.text "notes"
    t.date "period_end", null: false
    t.date "period_start", null: false
    t.string "reference_month", null: false
    t.integer "services_count", default: 0
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_commission_closings_on_employee_id"
    t.index ["establishment_id", "employee_id", "reference_month"], name: "idx_closings_est_emp_month", unique: true
    t.index ["establishment_id"], name: "index_commission_closings_on_establishment_id"
    t.index ["membership_id"], name: "index_commission_closings_on_membership_id"
    t.index ["status"], name: "index_commission_closings_on_status"
  end

  create_table "commissions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "appointment_id", null: false
    t.decimal "calculated_from_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "commission_closing_id"
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.bigint "establishment_id", null: false
    t.bigint "membership_id"
    t.datetime "paid_at"
    t.string "reference_month"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_commissions_on_appointment_id"
    t.index ["commission_closing_id"], name: "index_commissions_on_commission_closing_id"
    t.index ["employee_id"], name: "index_commissions_on_employee_id"
    t.index ["establishment_id"], name: "index_commissions_on_establishment_id"
    t.index ["membership_id"], name: "index_commissions_on_membership_id"
    t.index ["reference_month"], name: "index_commissions_on_reference_month"
    t.index ["status"], name: "index_commissions_on_status"
  end

  create_table "customer_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "csrf_token_digest", null: false
    t.bigint "customer_id", null: false
    t.datetime "expires_at", null: false
    t.string "refresh_token_digest", null: false
    t.uuid "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "expires_at"], name: "index_customer_sessions_on_customer_id_and_expires_at"
    t.index ["customer_id"], name: "index_customer_sessions_on_customer_id"
    t.index ["session_id"], name: "index_customer_sessions_on_session_id", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "auth_session_id"
    t.string "cellphone"
    t.datetime "consent_privacy_at"
    t.datetime "consent_terms_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.bigint "establishment_id", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "first_login_at"
    t.string "image"
    t.datetime "locked_at"
    t.integer "login_otp_attempts", default: 0, null: false
    t.string "login_otp_code"
    t.datetime "login_otp_sent_at"
    t.string "name", null: false
    t.datetime "password_changed_at"
    t.string "password_digest", null: false
    t.string "phone"
    t.string "refresh_token"
    t.datetime "refresh_token_expires_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.jsonb "trusted_ips", default: []
    t.datetime "updated_at", null: false
    t.index ["consent_privacy_at"], name: "index_customers_on_consent_privacy_at"
    t.index ["consent_terms_at"], name: "index_customers_on_consent_terms_at"
    t.index ["email", "establishment_id"], name: "index_customers_on_email_and_establishment_id", unique: true
    t.index ["establishment_id"], name: "index_customers_on_establishment_id"
    t.index ["locked_at"], name: "index_customers_on_locked_at"
    t.index ["refresh_token"], name: "index_customers_on_refresh_token", unique: true, where: "(refresh_token IS NOT NULL)"
    t.index ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true, where: "(reset_password_token IS NOT NULL)"
  end

  create_table "employee_schedule_exceptions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.date "exception_date", null: false
    t.string "kind", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "exception_date", "kind"], name: "idx_employee_schedule_exceptions_unique", unique: true
    t.index ["user_id"], name: "index_employee_schedule_exceptions_on_user_id"
  end

  create_table "employee_services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "service_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["service_id"], name: "index_employee_services_on_service_id"
    t.index ["user_id", "service_id"], name: "index_employee_services_on_user_id_and_service_id", unique: true
    t.index ["user_id"], name: "index_employee_services_on_user_id"
  end

  create_table "employee_working_hours", force: :cascade do |t|
    t.time "afternoon_end_time"
    t.time "afternoon_start_time"
    t.datetime "created_at", null: false
    t.time "end_time"
    t.boolean "is_available", default: true
    t.time "morning_end_time"
    t.time "morning_start_time"
    t.time "start_time"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "weekday", null: false
    t.index ["user_id", "weekday"], name: "index_employee_working_hours_on_user_and_weekday", unique: true
    t.index ["user_id"], name: "index_employee_working_hours_on_user_id"
  end

  create_table "establishment_memberships", force: :cascade do |t|
    t.boolean "active", default: true
    t.boolean "can_manage_establishment", default: false
    t.boolean "can_manage_financial", default: false, null: false
    t.boolean "can_manage_schedule", default: false, null: false
    t.boolean "can_manage_services", default: false, null: false
    t.boolean "can_manage_stock", default: false
    t.boolean "can_manage_team", default: false
    t.boolean "can_view_only_own_clients", default: true, null: false
    t.decimal "commission_bonus_percentage", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "establishment_id", null: false
    t.string "financial_model"
    t.decimal "financial_value", precision: 10, scale: 2
    t.string "pix_key"
    t.string "role", default: "employee", null: false
    t.string "specialty"
    t.string "tipo_vinculo", default: "autonomo"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["establishment_id", "user_id"], name: "index_memberships_on_establishment_and_user", unique: true
    t.index ["establishment_id"], name: "index_memberships_on_establishment_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.check_constraint "financial_value >= 0::numeric", name: "chk_memberships_financial_value_non_negative"
  end

  create_table "establishments", force: :cascade do |t|
    t.boolean "active", default: true
    t.jsonb "amenities", default: []
    t.integer "appointment_interval", default: 30, null: false
    t.string "banner"
    t.string "booking_mode", default: "time"
    t.string "category"
    t.string "cnpj"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.string "facebook"
    t.string "instagram"
    t.jsonb "legal_pages", default: {}
    t.string "logo"
    t.string "name", null: false
    t.boolean "online_booking_enabled", default: true
    t.bigint "owner_id", null: false
    t.jsonb "payment_methods", default: []
    t.string "phone"
    t.jsonb "public_settings", default: {}
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.jsonb "testimonials", default: []
    t.string "timezone", default: "America/Sao_Paulo"
    t.datetime "updated_at", null: false
    t.string "whatsapp"
    t.index ["cnpj"], name: "index_establishments_on_cnpj", unique: true
    t.index ["owner_id"], name: "index_establishments_on_owner_id"
    t.index ["slug"], name: "index_establishments_on_slug", unique: true
    t.index ["status"], name: "index_establishments_on_status"
  end

  create_table "financial_transactions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "appointment_id"
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "employee_id"
    t.bigint "establishment_id", null: false
    t.string "kind", null: false
    t.jsonb "metadata", default: {}, null: false
    t.date "occurred_on", null: false
    t.bigint "source_id"
    t.string "source_type"
    t.string "status", default: "paid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["appointment_id"], name: "index_financial_transactions_on_appointment_id"
    t.index ["category"], name: "index_financial_transactions_on_category"
    t.index ["employee_id"], name: "index_financial_transactions_on_employee_id"
    t.index ["establishment_id"], name: "index_financial_transactions_on_establishment_id"
    t.index ["kind"], name: "index_financial_transactions_on_kind"
    t.index ["occurred_on"], name: "index_financial_transactions_on_occurred_on"
    t.index ["source_type", "source_id"], name: "index_financial_transactions_on_source_type_and_source_id"
    t.index ["status"], name: "index_financial_transactions_on_status"
    t.index ["user_id"], name: "index_financial_transactions_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "establishment_id", null: false
    t.boolean "read", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["establishment_id"], name: "index_notifications_on_establishment_id"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "package_employees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "service_package_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["service_package_id", "user_id"], name: "index_package_employees_on_service_package_id_and_user_id", unique: true
    t.index ["service_package_id"], name: "index_package_employees_on_service_package_id"
    t.index ["user_id"], name: "index_package_employees_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "discount_percentage"
    t.integer "duration_months", default: 1, null: false
    t.boolean "highlight", default: false, null: false
    t.integer "max_appointments_per_month"
    t.integer "max_employees"
    t.integer "max_owner_sessions", default: 1, null: false
    t.integer "max_services"
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "promotion_active", default: false, null: false
    t.integer "promotion_duration_days"
    t.datetime "promotion_ends_at"
    t.datetime "promotion_starts_at"
    t.decimal "promotional_price", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_plans_on_active"
    t.index ["code"], name: "index_plans_on_code", unique: true
    t.index ["max_owner_sessions"], name: "index_plans_on_unique_active_owner_sessions", unique: true, where: "(active = true)"
    t.check_constraint "max_owner_sessions >= 1 AND max_owner_sessions <= 4", name: "plans_max_owner_sessions_range"
  end

  create_table "service_package_sales", force: :cascade do |t|
    t.string "cancellation_reason"
    t.datetime "created_at", null: false
    t.integer "current_cycle", default: 1, null: false
    t.bigint "customer_id"
    t.bigint "establishment_id", null: false
    t.string "payment_status", default: "pending", null: false
    t.bigint "service_package_id", null: false
    t.integer "sessions_total", default: 0, null: false
    t.integer "sessions_used", default: 0, null: false
    t.datetime "sold_at", null: false
    t.bigint "sold_by_id"
    t.string "status", default: "active", null: false
    t.decimal "total_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_service_package_sales_on_customer_id"
    t.index ["establishment_id"], name: "index_service_package_sales_on_establishment_id"
    t.index ["service_package_id"], name: "index_service_package_sales_on_service_package_id"
    t.index ["sold_at"], name: "index_service_package_sales_on_sold_at"
    t.index ["sold_by_id"], name: "index_service_package_sales_on_sold_by_id"
    t.index ["status"], name: "index_service_package_sales_on_status"
  end

  create_table "service_package_usages", force: :cascade do |t|
    t.bigint "appointment_id"
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "service_package_sale_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at", null: false
    t.index ["appointment_id"], name: "index_service_package_usages_on_appointment_id"
    t.index ["service_package_sale_id"], name: "index_service_package_usages_on_service_package_sale_id"
  end

  create_table "service_packages", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.integer "duration_minutes", default: 30, null: false
    t.bigint "establishment_id", null: false
    t.text "included_items"
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "service_id"
    t.integer "sessions_total", default: 4
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["active"], name: "index_service_packages_on_active"
    t.index ["deleted_at"], name: "index_service_packages_on_deleted_at"
    t.index ["establishment_id", "active"], name: "index_service_packages_on_establishment_id_and_active"
    t.index ["establishment_id", "name"], name: "index_service_packages_on_establishment_id_and_name"
    t.index ["establishment_id"], name: "index_service_packages_on_establishment_id"
    t.index ["service_id"], name: "index_service_packages_on_service_id"
    t.index ["user_id"], name: "index_service_packages_on_user_id"
    t.check_constraint "duration_minutes > 0", name: "chk_packages_duration_positive"
    t.check_constraint "price >= 0::numeric", name: "chk_packages_price_non_negative"
    t.check_constraint "sessions_total > 0", name: "chk_packages_sessions_positive"
  end

  create_table "services", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.integer "duration_minutes", default: 30, null: false
    t.bigint "establishment_id", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "service_type", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_services_on_active"
    t.index ["deleted_at"], name: "index_services_on_deleted_at"
    t.index ["establishment_id", "name"], name: "index_services_on_establishment_id_and_name"
    t.index ["establishment_id"], name: "index_services_on_establishment_id"
    t.index ["service_type"], name: "index_services_on_service_type"
    t.check_constraint "duration_minutes > 0", name: "chk_services_duration_positive"
    t.check_constraint "price >= 0::numeric", name: "chk_services_price_non_negative"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
  end

  create_table "stock_items", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "establishment_id", null: false
    t.integer "minimum_stock", default: 1, null: false
    t.string "name", null: false
    t.bigint "owner_user_id"
    t.integer "quantity", default: 0, null: false
    t.decimal "sale_price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "stock_scope", default: "loja", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_stock_items_on_active"
    t.index ["establishment_id", "name"], name: "index_stock_items_on_establishment_id_and_name"
    t.index ["establishment_id"], name: "index_stock_items_on_establishment_id"
    t.index ["minimum_stock"], name: "index_stock_items_on_minimum_stock"
    t.index ["owner_user_id"], name: "index_stock_items_on_owner_user_id"
    t.index ["stock_scope"], name: "index_stock_items_on_stock_scope"
    t.check_constraint "minimum_stock >= 0", name: "chk_stock_items_minimum_stock_non_negative"
    t.check_constraint "quantity >= 0", name: "chk_stock_items_quantity_non_negative"
    t.check_constraint "sale_price >= 0::numeric", name: "chk_stock_items_sale_price_non_negative"
  end

  create_table "subscription_cancellations", force: :cascade do |t|
    t.string "canceled_by_role", null: false
    t.datetime "created_at", null: false
    t.text "details"
    t.string "reason", null: false
    t.bigint "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["canceled_by_role"], name: "index_subscription_cancellations_on_canceled_by_role"
    t.index ["reason"], name: "index_subscription_cancellations_on_reason"
    t.index ["subscription_id"], name: "index_subscription_cancellations_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "billing_cycle"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.bigint "establishment_id", null: false
    t.datetime "expires_at"
    t.date "next_billing_date"
    t.bigint "plan_id", null: false
    t.decimal "price_paid", precision: 10, scale: 2
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["establishment_id"], name: "index_subscriptions_on_establishment_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.boolean "allow_password_change", default: false
    t.string "cellphone"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "consent_privacy_at"
    t.datetime "consent_terms_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "first_login_at"
    t.string "image"
    t.datetime "locked_at"
    t.integer "login_otp_attempts", default: 0, null: false
    t.string "login_otp_code"
    t.datetime "login_otp_sent_at"
    t.string "name"
    t.datetime "password_changed_at"
    t.string "phone"
    t.string "provider", default: "email", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "customer", null: false
    t.json "tokens"
    t.jsonb "trusted_ips", default: []
    t.string "uid", default: "", null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["role"], name: "index_users_on_single_super_admin", unique: true, where: "((role)::text = 'super_admin'::text)"
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "addresses", "establishments"
  add_foreign_key "appointment_feedbacks", "appointments"
  add_foreign_key "appointment_feedbacks", "customers"
  add_foreign_key "appointments", "customers"
  add_foreign_key "appointments", "establishments"
  add_foreign_key "appointments", "services"
  add_foreign_key "appointments", "users", column: "employee_id"
  add_foreign_key "archived_employees", "establishments"
  add_foreign_key "archived_employees", "users"
  add_foreign_key "archived_employees", "users", column: "archived_by_id"
  add_foreign_key "business_hours", "establishments"
  add_foreign_key "commission_closing_histories", "commission_closings"
  add_foreign_key "commission_closing_histories", "users"
  add_foreign_key "commission_closing_items", "appointments"
  add_foreign_key "commission_closing_items", "commission_closings"
  add_foreign_key "commission_closing_items", "commissions"
  add_foreign_key "commission_closings", "establishment_memberships", column: "membership_id"
  add_foreign_key "commission_closings", "establishments"
  add_foreign_key "commission_closings", "users", column: "closed_by_id"
  add_foreign_key "commission_closings", "users", column: "employee_id"
  add_foreign_key "commissions", "appointments"
  add_foreign_key "commissions", "commission_closings"
  add_foreign_key "commissions", "establishment_memberships", column: "membership_id"
  add_foreign_key "commissions", "establishments"
  add_foreign_key "commissions", "users", column: "employee_id"
  add_foreign_key "customer_sessions", "customers"
  add_foreign_key "customers", "establishments"
  add_foreign_key "employee_schedule_exceptions", "users"
  add_foreign_key "employee_services", "services"
  add_foreign_key "employee_services", "users"
  add_foreign_key "employee_working_hours", "users"
  add_foreign_key "establishment_memberships", "establishments"
  add_foreign_key "establishment_memberships", "users"
  add_foreign_key "establishments", "users", column: "owner_id"
  add_foreign_key "financial_transactions", "appointments"
  add_foreign_key "financial_transactions", "establishments"
  add_foreign_key "financial_transactions", "users"
  add_foreign_key "financial_transactions", "users", column: "employee_id"
  add_foreign_key "notifications", "establishments"
  add_foreign_key "notifications", "users"
  add_foreign_key "package_employees", "service_packages"
  add_foreign_key "package_employees", "users"
  add_foreign_key "service_package_sales", "customers"
  add_foreign_key "service_package_sales", "establishments"
  add_foreign_key "service_package_sales", "service_packages"
  add_foreign_key "service_package_sales", "users", column: "sold_by_id"
  add_foreign_key "service_package_usages", "appointments"
  add_foreign_key "service_package_usages", "service_package_sales"
  add_foreign_key "service_packages", "establishments"
  add_foreign_key "service_packages", "services"
  add_foreign_key "service_packages", "users"
  add_foreign_key "services", "establishments"
  add_foreign_key "stock_items", "establishments"
  add_foreign_key "stock_items", "users", column: "owner_user_id"
  add_foreign_key "subscription_cancellations", "subscriptions"
  add_foreign_key "subscriptions", "establishments"
  add_foreign_key "subscriptions", "plans"
end
