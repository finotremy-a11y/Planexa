# frozen_string_literal: true

class Admin::CompaniesController < Admin::BaseController
  before_action :set_company, only: [ :show, :destroy, :suspend, :reactivate ]

  def index
    @q = Company.includes(:user, :subscription).ransack(params[:q])
    @pagy, @companies = pagy(
      @q.result.order(created_at: :desc)
    )
  end

  def show
    @subscription  = @company.subscription
    @employees     = @company.employees.includes(:service_types)
    @service_types = @company.service_types
    @appointments  = @company.appointments
                             .includes(:service_type, :client_user, :employee)
                             .order(scheduled_at: :desc)
                             .limit(10)
    @setting = @company.setting
  end

  def destroy
    @company.destroy
    redirect_to admin_companies_path, notice: "Entreprise supprimée."
  end

  def suspend
    @company.suspended!
    @company.subscription&.update!(status: :suspended)
    CompanyMailer.account_suspended(@company).deliver_later
    redirect_to admin_company_path(@company),
      notice: "Compte de #{@company.name} suspendu."
  end

  def reactivate
    @company.active!
    @company.subscription&.update!(status: :active, suspended_at: nil)
    CompanyMailer.account_reactivated(@company).deliver_later
    redirect_to admin_company_path(@company),
      notice: "Compte de #{@company.name} réactivé."
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end
end
