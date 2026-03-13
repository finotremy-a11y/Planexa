class Company::EmployeeSkillsController < Company::BaseController
  before_action :set_employee

  def index
    @skills = @employee.employee_skills.includes(:service_type)
    @available_service_types = @company.service_types.active -
                               @employee.service_types.to_a
  end

  def create
    @skill = @employee.employee_skills.new(skill_params)
    if @skill.save
      redirect_to company_employee_skills_path(@employee),
        notice: "Aptitude ajoutée."
    else
      redirect_to company_employee_skills_path(@employee),
        alert: "Erreur : #{@skill.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @skill = @employee.employee_skills.find(params[:id])
    @skill.destroy
    redirect_to company_employee_skills_path(@employee),
      notice: "Aptitude supprimée."
  end

  private

  def set_employee
    @employee = @company.employees.find(params[:employee_id])
  end

  def skill_params
    params.require(:employee_skill).permit(:service_type_id, :level)
  end
end
