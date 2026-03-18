class Company::SchedulesController < Company::BaseController
  before_action :set_employee, only: [ :index, :create, :destroy ]

  def index
    @schedules  = @employee.schedules.recurring.order(:day_of_week)
    @exceptions = @employee.schedules.exceptions.order(:specific_date)
    @new_schedule = @employee.schedules.new
  end

  def create
    @new_schedule = @employee.schedules.new(schedule_params.merge(company: @company))
    if @new_schedule.save
      redirect_to company_employee_schedules_path(@employee),
        notice: "Créneau ajouté."
    else
      @schedules  = @employee.schedules.recurring.order(:day_of_week)
      @exceptions = @employee.schedules.exceptions.order(:specific_date)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    schedule = @company.schedules.find(params[:id])
    schedule.destroy
    redirect_back(fallback_location: company_employees_path,
                  notice: "Créneau supprimé.")
  end

  private

  def set_employee
    @employee = @company.employees.find(params[:employee_id])
  end

  def schedule_params
    params.require(:schedule).permit(:day_of_week, :start_time, :end_time,
                                      :specific_date, :available, :schedule_type)
  end
end
