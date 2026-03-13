class TrialEndingReminderJob < ApplicationJob
  queue_as :default

  def perform
    Subscription.trial_ending_soon.includes(:company).each do |subscription|
      CompanyMailer.trial_ending_soon(subscription.company).deliver_later
    end
  end
end
