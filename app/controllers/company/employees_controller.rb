class Company::EmployeesController < Company::BaseController
  before_action :set_employee, only: [ :show, :edit, :update, :destroy, :toggle_active ]

  def index
    @employees = @company.employees.includes(:service_types).order(:last_name)
    @pagy, @employees = pagy(@company.employees.includes(:service_types).order(:last_name))
  end

  def show
    @skills = @employee.employee_skills.includes(:service_type)
    @schedules = @employee.schedules.recurring.order(:day_of_week)
  end

  def new
    @employee = @company.employees.new
  end

  def create
    @employee = @company.employees.new(employee_params)
    if @employee.save
      redirect_to company_employee_path(@employee),
        notice: "#{@employee.full_name} a bien été ajouté(e)."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @employee.update(employee_params)
      redirect_to company_employee_path(@employee),
        notice: "Profil mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    redirect_to company_employees_path, notice: "Employé supprimé."
  end

  def toggle_active
    @employee.update!(active: !@employee.active)
    status = @employee.active? ? "activé(e)" : "désactivé(e)"
    redirect_to company_employees_path, notice: "#{@employee.full_name} #{status}."
  end

  private

  def set_employee
    @employee = @company.employees.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(:first_name, :last_name, :email, :phone)
  end
end
