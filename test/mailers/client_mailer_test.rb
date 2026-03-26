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

  test "appointment_reminder contient un lien de reconfirmation" do
    mail = ClientMailer.appointment_reminder(@appointment)
    assert_match "reconfirm", mail.body.encoded
    assert_match @appointment.id.to_s, mail.body.encoded
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

  # — review_request —
  test "review_request est envoyé au client" do
    review = create(:review, :pending,
      appointment: @appointment, company: @company, client_user: @client)
    mail = ClientMailer.review_request(review)
    assert_equal [ @client.email ], mail.to
  end

  test "review_request contient le nom de l'entreprise dans le sujet" do
    review = create(:review, :pending,
      appointment: @appointment, company: @company, client_user: @client)
    mail = ClientMailer.review_request(review)
    assert_match @company.name, mail.subject
  end

  test "review_request contient un lien avec le token" do
    review = create(:review, :pending,
      appointment: @appointment, company: @company, client_user: @client)
    mail = ClientMailer.review_request(review)
    assert_match review.token, mail.body.encoded
  end

  # — waitlist_notification —
  test "waitlist_notification est envoyé à l'email de l'inscription" do
    entry = create(:waitlist_entry, company: @company, service_type: @service)
    mail = ClientMailer.waitlist_notification(entry, @appointment)
    assert_equal [ entry.contact_email ], mail.to
  end

  test "waitlist_notification contient le nom de l'entreprise dans le sujet" do
    entry = create(:waitlist_entry, company: @company, service_type: @service)
    mail = ClientMailer.waitlist_notification(entry, @appointment)
    assert_match @company.name, mail.subject
  end

  test "waitlist_notification contient le nom de la prestation dans le sujet" do
    entry = create(:waitlist_entry, company: @company, service_type: @service)
    mail = ClientMailer.waitlist_notification(entry, @appointment)
    assert_match @service.name, mail.subject
  end

  test "waitlist_notification contient le token dans le body" do
    entry = create(:waitlist_entry, company: @company, service_type: @service)
    mail = ClientMailer.waitlist_notification(entry, @appointment)
    assert_match entry.token, mail.body.encoded
  end

  test "waitlist_notification fonctionne sans appointment (nil)" do
    entry = create(:waitlist_entry, company: @company, service_type: @service)
    mail = ClientMailer.waitlist_notification(entry, nil)
    assert_equal [ entry.contact_email ], mail.to
    assert_match @company.name, mail.subject
  end

  # — loyalty_threshold_reached —
  test "loyalty_threshold_reached est envoyé au client" do
    create(:discount_code, client_user: @client, company: @company)
    mail = ClientMailer.loyalty_threshold_reached(@client, @company)
    assert_equal [ @client.email ], mail.to
  end

  test "loyalty_threshold_reached contient le nom de l'entreprise dans le sujet" do
    create(:discount_code, client_user: @client, company: @company)
    mail = ClientMailer.loyalty_threshold_reached(@client, @company)
    assert_match @company.name, mail.subject
  end

  test "loyalty_threshold_reached contient le code dans le body" do
    code = create(:discount_code, client_user: @client, company: @company)
    mail = ClientMailer.loyalty_threshold_reached(@client, @company)
    assert_match code.code, mail.body.encoded
  end

  test "loyalty_threshold_reached contient récompense dans le sujet" do
    create(:discount_code, client_user: @client, company: @company)
    mail = ClientMailer.loyalty_threshold_reached(@client, @company)
    assert_match "récompense", mail.subject
  end

  # — i18n — email sent in recipient's locale —

  test "appointment_confirmed subject is in English when client locale is en" do
    en_client = create(:user, role: :client, locale: :en)
    appt = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  en_client,
      scheduled_at: 3.days.from_now.change(hour: 10, min: 0))
    mail = ClientMailer.appointment_confirmed(appt)
    assert_match "confirmed", mail.subject.downcase
    assert_match @company.name, mail.subject
  end

  test "appointment_confirmed subject is in Spanish when client locale is es" do
    es_client = create(:user, role: :client, locale: :es)
    appt = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  es_client,
      scheduled_at: 3.days.from_now.change(hour: 11, min: 0))
    mail = ClientMailer.appointment_confirmed(appt)
    assert_match "confirmada", mail.subject.downcase
    assert_match @company.name, mail.subject
  end

  test "appointment_cancelled subject is in English when client locale is en" do
    en_client = create(:user, role: :client, locale: :en)
    appt = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  en_client,
      scheduled_at: 3.days.from_now.change(hour: 12, min: 0))
    mail = ClientMailer.appointment_cancelled(appt)
    assert_match "cancelled", mail.subject.downcase
  end
end
