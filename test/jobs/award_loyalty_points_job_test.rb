# frozen_string_literal: true

require "test_helper"

class AwardLoyaltyPointsJobTest < ActiveSupport::TestCase
  setup do
    @company = create(:company)
    @company.company_setting.update!(loyalty_enabled: true, points_per_appointment: 10)
    @client  = create(:user, role: :client)
    @service = create(:service_type, company: @company)
    @appointment = create(:appointment, :completed,
      company: @company, service_type: @service, client_user: @client)
  end

  test "attribue des points pour un RDV complété" do
    assert_difference "LoyaltyPoint.count", 1 do
      AwardLoyaltyPointsJob.new.perform(@appointment.id)
    end
  end

  test "ne fait rien si le RDV est introuvable" do
    assert_no_difference "LoyaltyPoint.count" do
      AwardLoyaltyPointsJob.new.perform(999_999)
    end
  end

  test "ne fait rien si le RDV n'est pas complété" do
    @appointment.update!(status: :confirmed)
    assert_no_difference "LoyaltyPoint.count" do
      AwardLoyaltyPointsJob.new.perform(@appointment.id)
    end
  end

  test "ne double pas les points si exécuté deux fois" do
    AwardLoyaltyPointsJob.new.perform(@appointment.id)
    assert_no_difference "LoyaltyPoint.count" do
      AwardLoyaltyPointsJob.new.perform(@appointment.id)
    end
  end
end
