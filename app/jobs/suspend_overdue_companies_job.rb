class SuspendOverdueCompaniesJob < ApplicationJob
  queue_as :default

  def perform
    overdue = Subscription.past_due
                          .where("current_period_end < ?", 7.days.ago)
                          .includes(:company)

    overdue.each do |subscription|
      next if subscription.company.suspended?

      subscription.suspend!
      CompanyMailer.account_suspended(subscription.company).deliver_later
      Rails.logger.info "[SuspendJob] Suspended company ##{subscription.company.id} — #{subscription.company.name}"
    end
  end
end
