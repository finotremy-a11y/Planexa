require "test_helper"

class SuspendOverdueCompaniesJobTest < ActiveSupport::TestCase
  setup do
    @company = create(:company, status: :active)
    # Switch queue adapter to :test for this file
    @original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    ActiveJob::Base.queue_adapter = @original_adapter
  end

  test "suspend les entreprises dont l'abonnement est en retard depuis plus de 7 jours" do
    subscription = create(:subscription,
      company:            @company,
      status:             :past_due,
      current_period_end: 10.days.ago)

    SuspendOverdueCompaniesJob.new.perform

    assert @company.reload.suspended?
    assert subscription.reload.suspended?
  end

  test "ne suspend pas une entreprise déjà suspendue" do
    @company.update!(status: :suspended)
    create(:subscription,
      company:            @company,
      status:             :past_due,
      current_period_end: 10.days.ago)

    SuspendOverdueCompaniesJob.new.perform

    # L'entreprise reste suspendue, aucun email supplémentaire
    assert @company.reload.suspended?
    assert_equal 0, ActiveJob::Base.queue_adapter.enqueued_jobs.size
  end

  test "ne suspend pas si le retard est inférieur à 7 jours" do
    create(:subscription,
      company:            @company,
      status:             :past_due,
      current_period_end: 3.days.ago)

    SuspendOverdueCompaniesJob.new.perform

    assert @company.reload.active?
  end

  test "ne suspend pas les abonnements actifs" do
    create(:subscription,
      company:            @company,
      status:             :active,
      current_period_end: 10.days.ago)

    SuspendOverdueCompaniesJob.new.perform

    assert @company.reload.active?
  end

  test "envoie un email de suspension" do
    create(:subscription,
      company:            @company,
      status:             :past_due,
      current_period_end: 10.days.ago)

    SuspendOverdueCompaniesJob.new.perform

    enqueued_mail_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j| j[:job] == ActionMailer::MailDeliveryJob }
    assert_equal 1, enqueued_mail_jobs.size
  end
end
