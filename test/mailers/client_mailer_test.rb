require "test_helper"

class ClientMailerTest < ActionMailer::TestCase
  setup do
    @company = create(:company)
    @service = create(:service_type, company: @company)
    @client  = create(:user, role: :client)
    @appointment = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client,
      scheduled_at: 2.days.from_now.change(hour: 14, min: 0))
  end

  # — appointment_confirmed —
  test "appointment_confirmed est envoyé au client" do
    mail = ClientMailer.appointment_confirmed(@appointment)
    assert_equal [ @client.email ], mail.to
  end

  test "appointment_confirmed contient le nom de l'entreprise" do
    mail = ClientMailer.appointment_confirmed(@appointment)
    assert_match @company.name, mail.subject
  end

  test "appointment_confirmed a un sujet correct" do
    mail = ClientMailer.appointment_confirmed(@appointment)
    assert_match "confirmé", mail.subject
  end

  # — appointment_reminder —
  test "appointment_reminder est envoyé au client" do
    mail = ClientMailer.appointment_reminder(@appointment)
    assert_equal [ @client.email ], mail.to
  end

  test "appointment_reminder contient le nom de l'entreprise dans le sujet" do
    mail = ClientMailer.appointment_reminder(@appointment)
    assert_match @company.name, mail.subject
  end

  test "appointment_reminder est envoyé depuis l'adresse par défaut" do
    mail = ClientMailer.appointment_reminder(@appointment)
    assert_not_nil mail.from
  end

  # — appointment_cancelled —
  test "appointment_cancelled est envoyé au client" do
    mail = ClientMailer.appointment_cancelled(@appointment)
    assert_equal [ @client.email ], mail.to
  end

  test "appointment_cancelled contient 'annulé' dans le sujet" do
    mail = ClientMailer.appointment_cancelled(@appointment)
    assert_match "annulé", mail.subject
  end
end
