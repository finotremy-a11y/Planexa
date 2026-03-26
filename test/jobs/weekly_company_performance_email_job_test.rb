require "test_helper"

class WeeklyCompanyPerformanceEmailJobTest < ActiveSupport::TestCase
  setup do
    @original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    ActiveJob::Base.queue_adapter = @original_adapter
  end

  def enqueued_mail_count
    ActiveJob::Base.queue_adapter.enqueued_jobs.count { |j| j[:job] == ActionMailer::MailDeliveryJob }
  end

  test "envoie un email hebdomadaire aux entreprises actives" do
    active_company = create(:company, status: :active)
    create(:subscription, company: active_company, status: :active)

    WeeklyCompanyPerformanceEmailJob.new.perform

    assert_operator enqueued_mail_count, :>=, 1
  end

  test "n'envoie pas pour les entreprises suspendues" do
    suspended_company = create(:company, status: :suspended)
    create(:subscription, company: suspended_company, status: :active)

    WeeklyCompanyPerformanceEmailJob.new.perform

    assert_equal 0, enqueued_mail_count
  end
end
