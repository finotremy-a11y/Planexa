class Company::InactiveClientsController < Company::BaseController
  # GET /company/clients-inactifs
  def index
    @inactivity_days = normalize_inactivity_days(params[:days])
    cutoff = @inactivity_days.days.ago.end_of_day

    @inactive_clients = User.client
                            .joins(:client_appointments)
                            .where(appointments: { company_id: @company.id })
                            .group("users.id")
                            .having("MAX(appointments.scheduled_at) < ?", cutoff)
                            .select("users.*, MAX(appointments.scheduled_at) AS last_appointment_at, COUNT(appointments.id) AS appointments_count")
                            .order(Arel.sql("last_appointment_at ASC"))
  end

  private

  def normalize_inactivity_days(raw)
    parsed = raw.to_i
    return 60 if parsed.zero?

    parsed.clamp(7, 365)
  end
end
