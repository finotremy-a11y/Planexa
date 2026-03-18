require "test_helper"

class TrialEndingReminderJobTest < ActiveSupport::TestCase
  setup do
    @company = create(:company)
    @original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    ActiveJob::Base.queue_adapter = @original_adapter
  end

  def enqueued_mail_count
    ActiveJob::Base.queue_adapter.enqueued_jobs.count { |j| j[:job] == ActionMailer::MailDeliveryJob }
  end

  test "envoie un email de rappel pour chaque abonnement en essai se terminant bientôt" do
    create(:subscription,
      company:       @company,
      status:        :trialing,
      trial_ends_at: 2.days.from_now)

    TrialEndingReminderJob.new.perform

    assert_equal 1, enqueued_mail_count
  end

  test "n'envoie pas si la fin d'essai est dans plus de 3 jours" do
    create(:subscription,
      company:       @company,
      status:        :trialing,
      trial_ends_at: 5.days.from_now)

    TrialEndingReminderJob.new.perform

    assert_equal 0, enqueued_mail_count
  end

  test "n'envoie pas pour un abonnement actif (pas en trialing)" do
    create(:subscription,
      company: @company,
      status:  :active)

    TrialEndingReminderJob.new.perform

    assert_equal 0, enqueued_mail_count
  end

  test "envoie plusieurs emails si plusieurs abonnements concernés" do
    company2 = create(:company)
    create(:subscription, company: @company,  status: :trialing, trial_ends_at: 1.day.from_now)
    create(:subscription, company: company2, status: :trialing, trial_ends_at: 2.days.from_now)

    TrialEndingReminderJob.new.perform

    assert_equal 2, enqueued_mail_count
  end
end
