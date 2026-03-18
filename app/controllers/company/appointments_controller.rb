class Company::AppointmentsController < Company::BaseController
  before_action :set_appointment, only: [ :show, :edit, :update, :confirm,
                                          :cancel, :complete, :assign_employee ]

  def index
    @q = @company.appointments.ransack(params[:q])
    @pagy, @appointments = pagy(
      @q.result.includes(:client_user, :employee, :service_type).order(scheduled_at: :desc)
    )
  end

  def calendar
    @appointments = @company.appointments
                             .where(scheduled_at: Date.today.beginning_of_month..Date.today.end_of_month)
                             .includes(:employee, :service_type, :client_user)
  end

  def show; end

  def new
    @appointment = @company.appointments.new
    @appointment.scheduled_at = Time.current.beginning_of_hour + 1.hour
  end

  def create
    @appointment = @company.appointments.new(appointment_params.merge(booking_source: :manual))

    # Assignation automatique si le mode est activé et pas d'employé désigné
    if @company.setting.auto_assignment? && @appointment.employee_id.blank?
      @appointment.employee = @company.auto_assign_employee(
        @appointment.service_type,
        @appointment.scheduled_at,
        @appointment.duration_minutes
      )
    end

    if @appointment.save
      @appointment.confirmed! if @company.setting.booking_private?
      redirect_to company_appointment_path(@appointment),
        notice: "Rendez-vous créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @appointment.update(appointment_params)
      redirect_to company_appointment_path(@appointment), notice: "Rendez-vous mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm
    @appointment.confirmed!
    redirect_to company_appointment_path(@appointment), notice: "Rendez-vous confirmé."
  end

  def cancel
    @appointment.update!(status: :cancelled, cancellation_reason: params[:reason])
    redirect_to company_appointments_path, notice: "Rendez-vous annulé."
  end

  def complete
    @appointment.completed!
    redirect_to company_appointment_path(@appointment), notice: "Rendez-vous marqué comme terminé."
  end

  def assign_employee
    employee = @company.employees.find(params[:employee_id])
    @appointment.update!(employee: employee)
    redirect_to company_appointment_path(@appointment), notice: "Employé assigné."
  end

  def unassigned
    @appointments = @company.appointments.pending.unassigned
                             .includes(:service_type, :client_user)
                             .order(:scheduled_at)
  end

  private

  def set_appointment
    @appointment = @company.appointments.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:service_type_id, :employee_id, :scheduled_at,
                                         :duration_minutes, :client_notes, :internal_notes,
                                         :urgent, :client_user_id)
  end
end
