class WeeklyCompanyPerformanceEmailJob < ApplicationJob
  queue_as :default

  def perform
    Company.active.includes(:user).find_each do |company|
      next if company.user&.email.blank?

      CompanyMailer.weekly_performance_summary(company).deliver_later
    end
  end
end
