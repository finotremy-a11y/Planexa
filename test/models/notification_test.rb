# frozen_string_literal: true

require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    @company = create(:company)
    @st      = create(:service_type, company: @company)
    @appt    = create(:appointment, company: @company, service_type: @st, booking_source: :online)
  end

  # ── Validations ───────────────────────────────────────────────────────────

  test "valide avec les attributs corrects" do
    n = build(:notification, company: @company, kind: :new_booking)
    assert n.valid?, n.errors.full_messages.inspect
  end

  test "invalide sans company" do
    n = build(:notification, company: nil, kind: :new_booking)
    assert_not n.valid?
  end

  # ── Enum kind ─────────────────────────────────────────────────────────────

  test "tous les kinds sont définis" do
    assert Notification.kinds.keys.include?("new_booking")
    assert Notification.kinds.keys.include?("cancellation")
    assert Notification.kinds.keys.include?("payment")
    assert Notification.kinds.keys.include?("urgent")
  end

  # ── Scopes ────────────────────────────────────────────────────────────────

  test "scope unread exclut les notifications lues" do
    n_unread = create(:notification, company: @company, kind: :new_booking)
    n_read   = create(:notification, company: @company, kind: :new_booking,
                      read_at: 1.hour.ago)
    assert_includes Notification.unread, n_unread
    assert_not_includes Notification.unread, n_read
  end

  test "scope recent retourne au plus 20 notifications" do
    21.times { create(:notification, company: @company, kind: :new_booking) }
    assert_equal 20, Notification.recent.count
  end

  # ── Méthodes ─────────────────────────────────────────────────────────────

  test "read? retourne false pour une notification non lue" do
    n = create(:notification, company: @company, kind: :new_booking)
    assert_not n.read?
  end

  test "read? retourne true pour une notification lue" do
    n = create(:notification, company: @company, kind: :new_booking,
               read_at: Time.current)
    assert n.read?
  end

  test "mark_as_read! marque la notification comme lue" do
    n = create(:notification, company: @company, kind: :new_booking)
    n.mark_as_read!
    assert n.reload.read?
  end

  test "mark_as_read! est idempotent" do
    n = create(:notification, company: @company, kind: :new_booking,
               read_at: 1.hour.ago)
    assert_no_difference "Notification.unread.count" do
      n.mark_as_read!
    end
  end

  test "icon retourne le bon emoji pour chaque kind" do
    assert_equal "📅", create(:notification, company: @company, kind: :new_booking).icon
    assert_equal "❌", create(:notification, company: @company, kind: :cancellation).icon
    assert_equal "💳", create(:notification, company: @company, kind: :payment).icon
    assert_equal "🚨", create(:notification, company: @company, kind: :urgent).icon
  end

  test "summary_text retourne un texte pour chaque kind" do
    Notification.kinds.each_key do |kind|
      n = create(:notification, company: @company, kind: kind.to_sym)
      assert_not_nil n.summary_text, "summary_text nil pour #{kind}"
    end
  end

  # ── Callbacks Appointment ────────────────────────────────────────────────

  test "un rendez-vous online crée automatiquement une notification new_booking" do
    assert_difference "Notification.where(kind: :new_booking).count", 1 do
      create(:appointment, company: @company, service_type: @st, booking_source: :online)
    end
  end

  test "un rendez-vous manuel ne crée pas de notification" do
    assert_no_difference "Notification.count" do
      create(:appointment, company: @company, service_type: @st, booking_source: :manual)
    end
  end

  test "une annulation crée une notification cancellation" do
    appt = create(:appointment, company: @company, service_type: @st,
                  booking_source: :online, status: :pending)
    # Reset notification count after creation
    Notification.destroy_all

    assert_difference "Notification.where(kind: :cancellation).count", 1 do
      appt.cancelled!
    end
  end

  test "un rdv urgent crée une notification urgent" do
    appt = create(:appointment, company: @company, service_type: @st,
                  booking_source: :online, urgent: false)
    Notification.destroy_all

    assert_difference "Notification.where(kind: :urgent).count", 1 do
      appt.update!(urgent: true)
    end
  end
end
