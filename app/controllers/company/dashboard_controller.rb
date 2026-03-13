class Company::DashboardController < Company::BaseController
  def index
    @upcoming_appointments = @company.appointments
                                     .upcoming
                                     .includes(:client_user, :employee, :service_type)
                                     .limit(5)

    @unassigned_count = @company.appointments.pending.unassigned.count
    @today_appointments = @company.appointments.today.count
    @employees_count = @company.employees.active.count
    @monthly_revenue = @company.payments.successful
                               .where("paid_at >= ?", Time.current.beginning_of_month)
                               .sum(:amount_cents) / 100.0
  end
end
