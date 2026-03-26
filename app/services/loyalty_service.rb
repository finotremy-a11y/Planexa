# frozen_string_literal: true

# Service responsable de l'attribution des points de fidélité et de la
# génération automatique de codes de réduction lorsque le seuil est atteint.
class LoyaltyService
  attr_reader :errors

  def initialize(appointment)
    @appointment = appointment
    @company     = appointment.company
    @client      = appointment.client_user
    @setting     = @company.company_setting
    @errors      = []
  end

  # Attribue des points de fidélité après un RDV complété.
  # Vérifie si le seuil est atteint et génère un code promo le cas échéant.
  def award_points!
    return false unless eligible?

    ActiveRecord::Base.transaction do
      create_loyalty_point!
      check_threshold_and_generate_discount!
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  end

  # Déduit les points utilisés lors de l'échange contre un code promo.
  def redeem_points!(points_to_redeem)
    return add_error("Points insuffisants") unless sufficient_balance?(points_to_redeem)

    ActiveRecord::Base.transaction do
      LoyaltyPoint.create!(
        client_user: @client,
        company:     @company,
        points:      -points_to_redeem.abs,
        reason:      "redeemed"
      )
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  end

  def current_balance
    LoyaltyPoint.balance_for(@client, @company)
  end

  def progress_percentage
    return 0 unless @setting.loyalty_enabled?
    threshold = @setting.loyalty_points_threshold
    return 100 if threshold.zero?

    [ (current_balance.to_f / threshold * 100).floor, 100 ].min
  end

  private

  def eligible?
    return add_error("Fidélité désactivée") unless @setting.loyalty_enabled?
    return add_error("Client absent") unless @client.present?
    return add_error("RDV non complété") unless @appointment.completed?
    return add_error("Points déjà attribués") if points_already_awarded?

    true
  end

  def points_already_awarded?
    LoyaltyPoint.exists?(
      appointment: @appointment,
      client_user: @client,
      company:     @company,
      reason:      "earned"
    )
  end

  def create_loyalty_point!
    LoyaltyPoint.create!(
      client_user: @client,
      company:     @company,
      appointment: @appointment,
      points:      @setting.points_per_appointment,
      reason:      "earned"
    )
  end

  def check_threshold_and_generate_discount!
    balance = current_balance
    threshold = @setting.loyalty_points_threshold

    return unless threshold.positive? && balance >= threshold

    generate_discount_code!
    deduct_threshold_points!(threshold)
    send_threshold_notification!
  end

  def generate_discount_code!
    DiscountCode.create!(
      company:              @company,
      client_user:          @client,
      discount_type:        :fixed,
      discount_value_cents: @setting.loyalty_discount_value_cents,
      expires_at:           30.days.from_now
    )
  end

  def deduct_threshold_points!(threshold)
    LoyaltyPoint.create!(
      client_user: @client,
      company:     @company,
      points:      -threshold,
      reason:      "redeemed"
    )
  end

  def send_threshold_notification!
    ClientMailer.loyalty_threshold_reached(@client, @company).deliver_later
  end

  def sufficient_balance?(points)
    current_balance >= points
  end

  def add_error(message)
    @errors << message
    false
  end
end
