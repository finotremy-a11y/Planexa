# frozen_string_literal: true

require "test_helper"

class BookingGroupTest < ActiveSupport::TestCase
  setup do
    @company = create(:company)
    @client  = create(:user, role: :client)
    @st1     = create(:service_type, company: @company, duration_minutes: 30, price_cents: 2000)
    @st2     = create(:service_type, company: @company, duration_minutes: 45, price_cents: 3000)

    @booking_group = create(:booking_group, company: @company, client_user: @client,
                             total_amount_cents: 5000, status: :pending)
    @appt1 = create(:appointment, company: @company, service_type: @st1,
                     booking_group: @booking_group, status: :pending,
                     duration_minutes: @st1.duration_minutes,
                     scheduled_at: 2.days.from_now.change(hour: 10, min: 0))
    @appt2 = create(:appointment, company: @company, service_type: @st2,
                     booking_group: @booking_group, status: :pending,
                     duration_minutes: @st2.duration_minutes,
                     scheduled_at: 2.days.from_now.change(hour: 10, min: 30))
  end

  # ── Validations ───────────────────────────────────────────────────────────

  test "valide avec des attributs corrects" do
    bg = build(:booking_group, company: @company, client_user: @client,
               total_amount_cents: 1000)
    assert bg.valid?, bg.errors.full_messages.inspect
  end

  test "invalide si total_amount_cents est négatif" do
    bg = build(:booking_group, company: @company, total_amount_cents: -1)
    assert_not bg.valid?
    assert bg.errors[:total_amount_cents].any?
  end

  test "invalide sans company" do
    bg = build(:booking_group, company: nil, total_amount_cents: 1000)
    assert_not bg.valid?
  end

  # ── Enum status ───────────────────────────────────────────────────────────

  test "statut par défaut est pending" do
    bg = create(:booking_group, company: @company, total_amount_cents: 0)
    assert bg.pending?
  end

  test "transitions de statut fonctionnent" do
    @booking_group.confirmed!
    assert @booking_group.confirmed?
    @booking_group.cancelled!
    assert @booking_group.cancelled?
    @booking_group.completed!
    assert @booking_group.completed?
  end

  # ── Méthodes de calcul ────────────────────────────────────────────────────

  test "total_duration_minutes somme les durées des appointments" do
    assert_equal 75, @booking_group.total_duration_minutes
  end

  test "service_types retourne les types de prestation associés" do
    ids = @booking_group.service_types.pluck(:id)
    assert_includes ids, @st1.id
    assert_includes ids, @st2.id
  end

  # ── confirm_all! ──────────────────────────────────────────────────────────

  test "confirm_all! confirme le groupe et tous les appointments" do
    @booking_group.confirm_all!
    @booking_group.reload
    assert @booking_group.confirmed?
    @booking_group.appointments.each do |appt|
      assert appt.reload.confirmed?
    end
  end

  test "confirm_all! est atomique : le groupe reste pending si un appointment échoue" do
    # any_instance est nécessaire car confirm_all! charge de nouveaux objets AR
    # (pas les mêmes objets Ruby que @appt1/@appt2)
    Appointment.any_instance.stubs(:confirmed!).raises(ActiveRecord::RecordInvalid.new(Appointment.new))
    assert_raises(ActiveRecord::RecordInvalid) do
      @booking_group.confirm_all!
    end
    @booking_group.reload
    # La transaction a levé une erreur → le groupe doit rester pending
    assert @booking_group.pending?
  end

  # ── cancel_all! ───────────────────────────────────────────────────────────

  test "cancel_all! annule le groupe et tous les appointments" do
    @booking_group.cancel_all!
    @booking_group.reload
    assert @booking_group.cancelled?
    @booking_group.appointments.each do |appt|
      assert appt.reload.cancelled?
    end
  end

  # ── Scopes ────────────────────────────────────────────────────────────────

  test "scope for_company filtre par company" do
    other_company = create(:company)
    other_bg = create(:booking_group, company: other_company, total_amount_cents: 500)
    result = BookingGroup.for_company(@company)
    assert_includes result, @booking_group
    assert_not_includes result, other_bg
  end

  # ── Associations ─────────────────────────────────────────────────────────

  test "appartient à une company" do
    assert_equal @company, @booking_group.company
  end

  test "appartient optionnellement à un client_user" do
    bg = create(:booking_group, company: @company, client_user: nil, total_amount_cents: 0)
    assert_nil bg.client_user
  end

  test "destroy supprime les appointments associés" do
    assert_difference "Appointment.count", -2 do
      @booking_group.destroy
    end
  end
end
