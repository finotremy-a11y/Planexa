require "application_system_test_case"

class MultiBookingSystemTest < ApplicationSystemTestCase
  setup do
    @company = create(:company, status: :active)
    @company.setting.update!(
      booking_mode:    :booking_public,
      assignment_mode: :assignment_automatic,
      payment_mode:    :payment_external
    )

    @service1 = create(:service_type, company: @company, name: "Coupe femme",
                        duration_minutes: 30, price_cents: 2500, active: true)
    @service2 = create(:service_type, company: @company, name: "Coloration",
                        duration_minutes: 60, price_cents: 5000, active: true)

    @employee = create(:employee, company: @company, active: true)
    @employee.employee_skills.create!(service_type: @service1)
    @employee.employee_skills.create!(service_type: @service2)
    (0..6).each do |day|
      @employee.schedules.create!(
        company:       @company,
        day_of_week:   day,
        start_time:    "08:00",
        end_time:      "20:00",
        available:     true,
        schedule_type: :recurring
      )
    end

    @client = create(:user, role: :client)
  end

  # ── Flux complet : client connecté réserve 2 prestations ─────────────────

  test "client connecté peut réserver plusieurs prestations" do
    sign_in @client
    visit new_booking_path(company_id: @company.id)

    assert_text "Réserver plusieurs prestations"
    assert_text "Coupe femme"
    assert_text "Coloration"

    check "service_type_#{@service1.id}", allow_label_click: true
    check "service_type_#{@service2.id}", allow_label_click: true

    datetime = (Time.current + 2.days).change(hour: 10, min: 0, sec: 0)
                                      .strftime("%Y-%m-%dT%H:%M")

    page.execute_script(<<~JS)
      const field = document.querySelector('input[name="booking_group[scheduled_at]"]');
      field.removeAttribute('min');
      field.value = '#{datetime}';
      field.dispatchEvent(new Event('input', { bubbles: true }));
      field.dispatchEvent(new Event('change', { bubbles: true }));
    JS

    click_button "Confirmer la réservation"

    assert_text "Réservation confirmée"
    assert_text "Coupe femme"
    assert_text "Coloration"
    assert_equal 1, BookingGroup.count
    assert_equal 2, Appointment.count
  end

  # ── Flux anonyme ──────────────────────────────────────────────────────────

  test "client anonyme peut réserver plusieurs prestations" do
    visit new_booking_path(company_id: @company.id)

    assert_text "Réserver plusieurs prestations"

    check "service_type_#{@service1.id}", allow_label_click: true
    check "service_type_#{@service2.id}", allow_label_click: true

    datetime = (Time.current + 2.days).change(hour: 14, min: 0, sec: 0)
                                      .strftime("%Y-%m-%dT%H:%M")

    page.execute_script(<<~JS)
      const field = document.querySelector('input[name="booking_group[scheduled_at]"]');
      field.removeAttribute('min');
      field.value = '#{datetime}';
      field.dispatchEvent(new Event('input', { bubbles: true }));
      field.dispatchEvent(new Event('change', { bubbles: true }));
    JS

    click_button "Confirmer la réservation"

    assert_text "Réservation confirmée"
    assert_equal 1, BookingGroup.count
    assert_nil BookingGroup.last.client_user
  end

  # ── Validation : moins de 2 prestations ──────────────────────────────────

  test "affiche une erreur si moins de 2 prestations sélectionnées" do
    sign_in @client
    visit new_booking_path(company_id: @company.id)

    check "service_type_#{@service1.id}", allow_label_click: true
    # Ne cocher qu'une seule prestation

    datetime = (Time.current + 2.days).change(hour: 10, min: 0, sec: 0)
                                      .strftime("%Y-%m-%dT%H:%M")

    page.execute_script(<<~JS)
      const field = document.querySelector('input[name="booking_group[scheduled_at]"]');
      field.removeAttribute('min');
      field.value = '#{datetime}';
    JS

    click_button "Confirmer la réservation"

    assert_text "Sélectionnez au moins 2 prestations"
    assert_equal 0, BookingGroup.count
  end

  # ── Page confirmation affiche le détail ──────────────────────────────────

  test "page de confirmation affiche durée et montant total" do
    sign_in @client
    visit new_booking_path(company_id: @company.id)

    check "service_type_#{@service1.id}", allow_label_click: true
    check "service_type_#{@service2.id}", allow_label_click: true

    datetime = (Time.current + 2.days).change(hour: 10, min: 0, sec: 0)
                                      .strftime("%Y-%m-%dT%H:%M")

    page.execute_script(<<~JS)
      const field = document.querySelector('input[name="booking_group[scheduled_at]"]');
      field.removeAttribute('min');
      field.value = '#{datetime}';
    JS

    click_button "Confirmer la réservation"

    assert_text "Réservation confirmée"
    # Total : 2500 + 5000 = 75,00 €
    assert_text "75"
  end
end
