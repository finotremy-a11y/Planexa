require "test_helper"

class CompanyMailerTest < ActionMailer::TestCase
  setup do
    @company      = create(:company)
    @subscription = create(:subscription,
      company:       @company,
      status:        :trialing,
      trial_ends_at: 3.days.from_now)
    @service = create(:service_type, company: @company)
    @client  = create(:user, role: :client)
    @appointment = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client,
      scheduled_at: 2.days.from_now.change(hour: 10, min: 0))
  end

  # — welcome_trial —
  test "welcome_trial est envoyé au owner de l'entreprise" do
    mail = CompanyMailer.welcome_trial(@company)
    assert_equal [ @company.user.email ], mail.to
  end

  test "welcome_trial contient 'essai gratuit' dans le sujet" do
    mail = CompanyMailer.welcome_trial(@company)
    assert_match "essai", mail.subject
  end

  # — trial_ending_soon —
  test "trial_ending_soon est envoyé au owner" do
    mail = CompanyMailer.trial_ending_soon(@company)
    assert_equal [ @company.user.email ], mail.to
  end

  test "trial_ending_soon mentionne les jours restants dans le sujet" do
    mail = CompanyMailer.trial_ending_soon(@company)
    assert_match "jours", mail.subject
  end

  # — payment_failed —
  test "payment_failed est envoyé au owner" do
    mail = CompanyMailer.payment_failed(@company)
    assert_equal [ @company.user.email ], mail.to
  end

  test "payment_failed mentionne l'échec dans le sujet" do
    mail = CompanyMailer.payment_failed(@company)
    assert_match "Échec", mail.subject
  end

  # — account_suspended —
  test "account_suspended est envoyé au owner" do
    mail = CompanyMailer.account_suspended(@company)
    assert_equal [ @company.user.email ], mail.to
  end

  test "account_suspended mentionne la suspension dans le sujet" do
    mail = CompanyMailer.account_suspended(@company)
    assert_match "suspendu", mail.subject
  end

  # — account_reactivated —
  test "account_reactivated est envoyé au owner" do
    mail = CompanyMailer.account_reactivated(@company)
    assert_equal [ @company.user.email ], mail.to
  end

  test "account_reactivated mentionne la réactivation dans le sujet" do
    mail = CompanyMailer.account_reactivated(@company)
    assert_match "réactivé", mail.subject
  end

  # — subscription_canceled —
  test "subscription_canceled est envoyé au owner" do
    mail = CompanyMailer.subscription_canceled(@company)
    assert_equal [ @company.user.email ], mail.to
  end

  test "subscription_canceled mentionne l'annulation dans le sujet" do
    mail = CompanyMailer.subscription_canceled(@company)
    assert_match "annulé", mail.subject
  end

  # — new_appointment —
  test "new_appointment est envoyé au owner de la company" do
    mail = CompanyMailer.new_appointment(@appointment)
    assert_equal [ @company.user.email ], mail.to
  end

  test "new_appointment mentionne l'heure du RDV dans le sujet" do
    mail = CompanyMailer.new_appointment(@appointment)
    assert_match "rendez-vous", mail.subject.downcase
  end

  test "weekly_performance_summary est envoyé au owner" do
    mail = CompanyMailer.weekly_performance_summary(@company)
    assert_equal [ @company.user.email ], mail.to
  end

  test "weekly_performance_summary contient les metriques principales" do
    period_start = 6.days.ago.beginning_of_day
    period_end = Time.current.end_of_day

    priced_service = create(:service_type, company: @company, price_cents: 2500)
    create(:appointment, company: @company, service_type: priced_service,
                         booking_source: :online, status: :confirmed, created_at: 2.days.ago)
    create(:appointment, company: @company, service_type: priced_service,
                         booking_source: :online, status: :cancelled, created_at: 3.days.ago, updated_at: 1.day.ago)
    review_appointment = create(:appointment, company: @company, service_type: priced_service)
    create(:review, :submitted, company: @company, appointment: review_appointment, published_at: 1.day.ago)

    mail = CompanyMailer.weekly_performance_summary(@company, period_start: period_start, period_end: period_end)
    body = mail.body.encoded

    assert_match "Reservations", body
    assert_match "Annulations", body
    assert_match "Avis publies", body
    assert_match(/CA estime<\/strong><br>\s*<span[^>]*>\d+[\s\d]*,\d{2}\s*€/m, body)
  end
end
