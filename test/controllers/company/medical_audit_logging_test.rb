require "test_helper"

class Company::MedicalAuditLoggingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user, :company_admin)
    @company = create(:company,
      user: @user,
      professional_category: :healthcare_professional,
      health_specialty: "Generaliste",
      convention_sector: :sector_1,
      cancellation_policy: "Annulation 24h")
    create(:subscription, company: @company, status: :active)
    sign_in @user
    @service = create(:service_type, company: @company)
  end

  test "PATCH settings cree un audit log sur changement sensible" do
    assert_difference("MedicalAuditLog.count", 1) do
      patch company_settings_path, params: {
        company_setting: {
          booking_mode: "booking_public",
          payment_mode: "payment_external",
          assignment_mode: "assignment_manual",
          slot_interval_minutes: 20,
          buffer_between_appointments_minutes: 10,
          allow_controlled_overbooking: true,
          overbooking_limit_per_slot: 1,
          emergency_daily_capacity: 3
        }
      }
    end

    assert_equal "medical_settings_updated", MedicalAuditLog.order(:id).last.action
  end

  test "POST company_closures cree un audit log" do
    assert_difference("MedicalAuditLog.count", 1) do
      post company_company_closures_path, params: {
        company_closure: {
          starts_at: 2.days.from_now.change(hour: 9),
          ends_at: 2.days.from_now.change(hour: 12),
          reason: "Formation"
        }
      }
    end

    assert_equal "company_closure_created", MedicalAuditLog.order(:id).last.action
  end

  test "POST appointments cree un audit log medical" do
    assert_difference("MedicalAuditLog.count", 1) do
      post company_appointments_path, params: {
        appointment: {
          service_type_id: @service.id,
          scheduled_at: 2.days.from_now.change(hour: 10, min: 0),
          duration_minutes: 30,
          urgent: true
        }
      }
    end

    assert_equal "medical_appointment_created", MedicalAuditLog.order(:id).last.action
  end
end
