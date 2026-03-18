require "test_helper"

class AppointmentPolicyTest < ActiveSupport::TestCase
  setup do
    @admin         = create(:user, :admin)
    @company_user  = create(:user, :company_admin)
    @company       = create(:company, user: @company_user)
    @client        = create(:user, role: :client)
    @other_client  = create(:user, role: :client)
    @appointment   = create(:appointment, :with_client,
      company:      @company,
      service_type: create(:service_type, company: @company),
      client_user:  @client)
  end

  # — Admin peut tout faire —
  test "admin peut faire show" do
    assert AppointmentPolicy.new(@admin, @appointment).show?
  end

  test "admin peut destroy" do
    assert AppointmentPolicy.new(@admin, @appointment).destroy?
  end

  test "admin peut confirm" do
    assert AppointmentPolicy.new(@admin, @appointment).confirm?
  end

  # — Company owner peut confirmer/annuler mais pas destroy —
  test "company owner peut confirm" do
    assert AppointmentPolicy.new(@company_user, @appointment).confirm?
  end

  test "company owner peut cancel" do
    assert AppointmentPolicy.new(@company_user, @appointment).cancel?
  end

  test "company owner ne peut pas destroy" do
    assert_not AppointmentPolicy.new(@company_user, @appointment).destroy?
  end

  # — Client peut show et cancel son propre RDV —
  test "client peut show son RDV" do
    assert AppointmentPolicy.new(@client, @appointment).show?
  end

  test "client peut cancel son RDV" do
    assert AppointmentPolicy.new(@client, @appointment).cancel?
  end

  # — Autre client ne peut rien faire —
  test "autre client ne peut pas show" do
    assert_not AppointmentPolicy.new(@other_client, @appointment).show?
  end

  test "autre client ne peut pas cancel" do
    assert_not AppointmentPolicy.new(@other_client, @appointment).cancel?
  end
end
