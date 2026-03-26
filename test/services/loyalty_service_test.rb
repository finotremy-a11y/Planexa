# frozen_string_literal: true

require "test_helper"

class LoyaltyServiceTest < ActiveSupport::TestCase
  setup do
    @company = create(:company)
    @company.company_setting.update!(
      loyalty_enabled: true,
      points_per_appointment: 10,
      loyalty_points_threshold: 50,
      loyalty_discount_value_cents: 1000
    )
    @client  = create(:user, role: :client)
    @service = create(:service_type, company: @company)
    @appointment = create(:appointment, :completed,
      company: @company, service_type: @service, client_user: @client)
  end

  # ── award_points! ─────────────────────────────────────────────────────────
  test "award_points! crée un point de fidélité" do
    service = LoyaltyService.new(@appointment)
    assert_difference "LoyaltyPoint.count", 1 do
      assert service.award_points!
    end
    lp = LoyaltyPoint.last
    assert_equal @client, lp.client_user
    assert_equal @company, lp.company
    assert_equal @appointment, lp.appointment
    assert_equal 10, lp.points
    assert_equal "earned", lp.reason
  end

  test "award_points! refuse si fidélité désactivée" do
    @company.company_setting.update!(loyalty_enabled: false)
    service = LoyaltyService.new(@appointment)
    assert_not service.award_points!
    assert_includes service.errors, "Fidélité désactivée"
  end

  test "award_points! refuse si RDV non complété" do
    @appointment.update!(status: :confirmed)
    service = LoyaltyService.new(@appointment)
    assert_not service.award_points!
    assert_includes service.errors, "RDV non complété"
  end

  test "award_points! refuse si points déjà attribués (idempotence)" do
    service = LoyaltyService.new(@appointment)
    assert service.award_points!
    service2 = LoyaltyService.new(@appointment)
    assert_not service2.award_points!
    assert_includes service2.errors, "Points déjà attribués"
  end

  test "award_points! refuse si client absent" do
    @appointment.update_column(:client_user_id, nil)
    @appointment.reload
    service = LoyaltyService.new(@appointment)
    assert_not service.award_points!
    assert_includes service.errors, "Client absent"
  end

  # ── Seuil et code promo ───────────────────────────────────────────────────
  test "génère un code promo quand le seuil est atteint" do
    # Ajouter 40 points existants, le prochain award (10) atteindra 50
    create(:loyalty_point, client_user: @client, company: @company, points: 40, reason: "earned")
    service = LoyaltyService.new(@appointment)

    assert_difference "DiscountCode.count", 1 do
      service.award_points!
    end

    code = DiscountCode.last
    assert_equal @client, code.client_user
    assert_equal @company, code.company
    assert_equal 1000, code.discount_value_cents
    assert code.usable?
  end

  test "déduit les points du seuil après génération du code" do
    create(:loyalty_point, client_user: @client, company: @company, points: 40, reason: "earned")
    service = LoyaltyService.new(@appointment)
    service.award_points!

    # Balance: 40 + 10 (earned) - 50 (redeemed for threshold) = 0
    assert_equal 0, LoyaltyPoint.balance_for(@client, @company)
  end

  test "envoie un email quand le seuil est atteint" do
    create(:loyalty_point, client_user: @client, company: @company, points: 40, reason: "earned")
    service = LoyaltyService.new(@appointment)

    mock_mail = mock("mail")
    mock_mail.expects(:deliver_later).once
    ClientMailer.expects(:loyalty_threshold_reached).with(@client, @company).returns(mock_mail)

    service.award_points!
  end

  test "ne génère pas de code si le seuil n'est pas atteint" do
    service = LoyaltyService.new(@appointment)
    assert_no_difference "DiscountCode.count" do
      service.award_points!
    end
  end

  # ── redeem_points! ────────────────────────────────────────────────────────
  test "redeem_points! déduit les points" do
    create(:loyalty_point, client_user: @client, company: @company, points: 20, reason: "earned")
    service = LoyaltyService.new(@appointment)

    assert service.redeem_points!(10)
    assert_equal 10, LoyaltyPoint.balance_for(@client, @company)
  end

  test "redeem_points! refuse si points insuffisants" do
    service = LoyaltyService.new(@appointment)
    assert_not service.redeem_points!(10)
    assert_includes service.errors, "Points insuffisants"
  end

  # ── progress_percentage ────────────────────────────────────────────────────
  test "progress_percentage retourne le pourcentage correct" do
    create(:loyalty_point, client_user: @client, company: @company, points: 25, reason: "earned")
    service = LoyaltyService.new(@appointment)
    assert_equal 50, service.progress_percentage
  end

  test "progress_percentage retourne 0 si fidélité désactivée" do
    @company.company_setting.update!(loyalty_enabled: false)
    service = LoyaltyService.new(@appointment)
    assert_equal 0, service.progress_percentage
  end

  test "progress_percentage ne dépasse pas 100" do
    create(:loyalty_point, client_user: @client, company: @company, points: 200, reason: "earned")
    service = LoyaltyService.new(@appointment)
    assert_equal 100, service.progress_percentage
  end

  test "progress_percentage retourne 100 si seuil à zéro" do
    @company.company_setting.update!(loyalty_points_threshold: 0)
    service = LoyaltyService.new(@appointment)
    assert_equal 100, service.progress_percentage
  end
end
