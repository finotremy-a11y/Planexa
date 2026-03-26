class Company::DashboardController < Company::BaseController
  def index
    @upcoming_appointments = @company.appointments
                                     .upcoming
                                     .includes(:client_user, :employee, :service_type)
                                     .limit(5)

    @unassigned_count = @company.appointments.pending.unassigned.count
    @today_appointments = @company.appointments.today.count
    @bookings_generated_this_month = @company.appointments.online
                           .where(created_at: Time.current.beginning_of_month..Time.current)
                           .count
    @estimated_turnover_this_month = @company.appointments.online
                         .where(created_at: Time.current.beginning_of_month..Time.current)
                         .where.not(status: :cancelled)
                         .joins(:service_type)
                         .sum("service_types.price_cents") / 100.0
    @no_show_avoided_this_month = compute_no_show_avoided_this_month
    @employees_count = @company.employees.active.count
    @monthly_revenue = @company.payments.successful
                               .where("paid_at >= ?", Time.current.beginning_of_month)
                               .sum(:amount_cents) / 100.0

    @onboarding_items = @company.onboarding_checklist_items
    @onboarding_completion_percentage = @company.onboarding_completion_percentage
    @ready_to_receive_bookings = @company.ready_to_receive_bookings?
    @onboarding_blockers = @company.onboarding_blockers
  end

  private

  def compute_no_show_avoided_this_month
    period = Time.current.beginning_of_month..Time.current
    attended_scope = @company.appointments
                            .where(scheduled_at: period)
                            .where(status: [ :confirmed, :completed ])

    reconfirmed_ids = attended_scope.where.not(reconfirmed_at: nil).pluck(:id)

    deposit_protected_ids = attended_scope
                            .joins(:service_type, :payment)
                            .merge(Payment.succeeded)
                            .where.not(service_types: { deposit_kind: ServiceType.deposit_kinds[:none] })
                            .pluck(:id)

    reminded_ids = attended_scope
                   .joins(:reminder_deliveries)
                   .merge(ReminderDelivery.sent)
                   .distinct
                   .pluck(:id)

    (reconfirmed_ids + deposit_protected_ids + reminded_ids).uniq.count
  end
end
