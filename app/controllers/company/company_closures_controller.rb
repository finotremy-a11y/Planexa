class Company::CompanyClosuresController < Company::BaseController
  before_action :set_company_closure, only: [ :destroy ]

  def index
    @company_closures = @company.company_closures.order(starts_at: :asc)
  end

  def new
    @company_closure = @company.company_closures.new(
      starts_at: Time.current.beginning_of_day,
      ends_at: Time.current.end_of_day
    )
  end

  def create
    @company_closure = @company.company_closures.new(company_closure_params)

    if @company_closure.save
      MedicalAuditLogger.log!(
        company: @company,
        user: current_user,
        action: "company_closure_created",
        record: @company_closure,
        metadata: {
          starts_at: @company_closure.starts_at,
          ends_at: @company_closure.ends_at
        }
      )
      redirect_to company_company_closures_path, notice: "Fermeture ponctuelle enregistree."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    MedicalAuditLogger.log!(
      company: @company,
      user: current_user,
      action: "company_closure_deleted",
      record: @company_closure,
      metadata: {
        starts_at: @company_closure.starts_at,
        ends_at: @company_closure.ends_at
      }
    )
    @company_closure.destroy
    redirect_to company_company_closures_path, notice: "Fermeture ponctuelle supprimee."
  end

  private

  def set_company_closure
    @company_closure = @company.company_closures.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  def company_closure_params
    params.require(:company_closure).permit(:starts_at, :ends_at, :reason, :note)
  end
end
