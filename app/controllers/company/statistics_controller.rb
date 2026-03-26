# frozen_string_literal: true

require "csv"

class Company::StatisticsController < Company::BaseController
  ALLOWED_PERIODS = [ 7, 30, 90 ].freeze

  def index
    @period   = sanitize_period(params[:period])
    @range    = @period.days.ago.beginning_of_day..Time.current.end_of_day

    appointments = @company.appointments.where(scheduled_at: @range)
    payments     = @company.payments.successful.where(paid_at: @range)

    build_appointment_kpis(appointments)
    build_revenue_kpis(payments)
    build_chart_data(appointments, payments)
    build_rankings(appointments)
  end

  def export_csv
    @period = sanitize_period(params[:period])
    @range  = @period.days.ago.beginning_of_day..Time.current.end_of_day

    appointments = @company.appointments
                           .where(scheduled_at: @range)
                           .includes(:service_type, :client_user, :employee)
                           .order(:scheduled_at)

    csv_data = CSV.generate(headers: true, col_sep: ";") do |csv|
      csv << [ "Date", "Heure", "Prestation", "Client", "Employé", "Statut", "Montant (€)" ]

      appointments.each do |appt|
        csv << [
          appt.scheduled_at.strftime("%d/%m/%Y"),
          appt.scheduled_at.strftime("%H:%M"),
          appt.service_type&.name,
          appt.client_user&.full_name || "—",
          appt.employee&.full_name    || "—",
          I18n.t("appointment.statuses.#{appt.status}", default: appt.status.humanize),
          appt.payment&.succeeded? ? format("%.2f", appt.payment.amount_cents / 100.0) : "0.00"
        ]
      end
    end

    filename = "statistiques_#{@period}j_#{Date.today.strftime('%Y%m%d')}.csv"
    send_data csv_data,
              filename: filename,
              type: "text/csv; charset=utf-8",
              disposition: "attachment"
  end

  private

  def sanitize_period(raw)
    val = raw.to_i
    ALLOWED_PERIODS.include?(val) ? val : 30
  end

  def build_appointment_kpis(appointments)
    @total_appointments    = appointments.count
    @confirmed_count       = appointments.confirmed.count
    @completed_count       = appointments.completed.count
    @cancelled_count       = appointments.cancelled.count
    @no_show_count         = appointments.no_show.count
    @no_show_rate          = @total_appointments.positive? ? (@no_show_count.to_f / @total_appointments * 100).round(1) : 0.0
    @unique_clients_count  = appointments.where.not(client_user_id: nil).distinct.count(:client_user_id)
  end

  def build_revenue_kpis(payments)
    @total_revenue_cents  = payments.sum(:amount_cents)
    count                 = payments.count
    @avg_basket_cents     = count.positive? ? (payments.sum(:amount_cents).to_f / count).round : 0
  end

  def build_chart_data(appointments, payments)
    # Groupdate: appointments by day for the period
    @appointments_by_day = appointments.group_by_day(:scheduled_at, range: @range).count

    # Groupdate: revenue by week (or by day if 7-day period)
    if @period <= 7
      @revenue_by_period = payments.group_by_day(:paid_at, range: @range).sum(:amount_cents)
                                   .transform_values { |v| (v / 100.0).round(2) }
    else
      @revenue_by_period = payments.group_by_week(:paid_at, range: @range).sum(:amount_cents)
                                   .transform_values { |v| (v / 100.0).round(2) }
    end
  end

  def build_rankings(appointments)
    @top_services = appointments
      .joins(:service_type)
      .group("service_types.name")
      .order("count_all DESC")
      .limit(5)
      .count

    @top_employees = appointments
      .joins(:employee)
      .where.not(employee_id: nil)
      .joins("JOIN employees ON employees.id = appointments.employee_id")
      .group("employees.first_name || ' ' || employees.last_name")
      .order("count_all DESC")
      .limit(5)
      .count
  end
end
