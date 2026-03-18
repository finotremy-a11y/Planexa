require "application_system_test_case"

class AppointmentBookingTest < ApplicationSystemTestCase
  setup do
    @company = create(:company, status: :active)
    @company.setting.update!(
      booking_mode: :booking_public,
      assignment_mode: :assignment_automatic,
      payment_mode: :payment_external
    )
    @service  = create(:service_type, company: @company, name: "Plomberie")
    @employee = create(:employee, company: @company)
    create(:employee_skill, employee: @employee, service_type: @service)
    create(:schedule,
      employee:      @employee,
      company:       @company,
      day_of_week:   1,
      start_time:    "08:00",
      end_time:      "18:00",
      schedule_type: "recurring",
      available:     true)
    @client = create(:user, role: :client)
  end

  test "client peut rechercher une entreprise" do
    sign_in @client
    visit search_path
    fill_in "Nom de l'entreprise", with: @company.name[0..3]
    click_button "Rechercher"
    assert_text @company.name
  end

  test "client peut voir la fiche d'une entreprise" do
    sign_in @client
    visit company_public_path(@company)
    assert_text @company.name
    assert_text "Plomberie"
  end

  test "client peut prendre un RDV en ligne" do
    sign_in @client
    visit new_appointment_path(company_id: @company.id)
    assert_text "Prendre rendez-vous"

    appointment_time = (Time.current + 2.days).change(min: 0)
    datetime = appointment_time.strftime("%Y-%m-%dT%H:%M")

    choose "appointment_service_type_id_#{@service.id}", allow_label_click: true
    page.execute_script(<<~JS)
      const field = document.getElementById('appointment_scheduled_at');
      field.removeAttribute('min');
      field.value = '#{datetime}';
      field.dispatchEvent(new Event('input', { bubbles: true }));
      field.dispatchEvent(new Event('change', { bubbles: true }));
    JS
    click_button "Confirmer la demande →"

    assert_text "Demande envoyée"
    assert_equal 1, Appointment.count
  end
end
