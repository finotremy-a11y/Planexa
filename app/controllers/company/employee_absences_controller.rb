# frozen_string_literal: true

class Company::EmployeeAbsencesController < Company::BaseController
  before_action :set_employee
  before_action :set_absence, only: [ :edit, :update, :destroy ]

  def index
    @absences = @employee.employee_absences.order(starts_at: :desc)
    @upcoming = @absences.upcoming
    @past     = @absences.past
    @active   = @absences.active
  end

  def new
    @absence = @employee.employee_absences.new(
      starts_at: Time.current.beginning_of_day,
      ends_at:   (Time.current + 1.day).end_of_day
    )
  end

  def create
    @absence = @employee.employee_absences.new(absence_params)
    if @absence.save
      redirect_to company_employee_employee_absences_path(@employee),
        notice: "Absence ajoutée pour #{@employee.full_name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @absence.update(absence_params)
      redirect_to company_employee_employee_absences_path(@employee),
        notice: "Absence mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @absence.destroy
    redirect_to company_employee_employee_absences_path(@employee),
      notice: "Absence supprimée."
  end

  private

  def set_employee
    @employee = @company.employees.find(params[:employee_id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  def set_absence
    @absence = @employee.employee_absences.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  def absence_params
    params.require(:employee_absence).permit(:starts_at, :ends_at, :reason, :note)
  end
end
