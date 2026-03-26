# frozen_string_literal: true

class Client::LoyaltyController < Client::BaseController
  def index
    @companies_with_loyalty = companies_with_loyalty_data
  end

  def show
    company_ids = current_user.loyalty_points.select(:company_id).distinct
    @company  = Company.where(id: company_ids).find(params[:id])
    @setting  = @company.company_setting
    @balance  = LoyaltyPoint.balance_for(current_user, @company)
    @progress = LoyaltyService.new(placeholder_appointment(@company)).progress_percentage
    @history  = current_user.loyalty_points
                            .where(company: @company)
                            .order(created_at: :desc)
                            .limit(50)
    @discount_codes = current_user.discount_codes
                                  .where(company: @company)
                                  .order(created_at: :desc)
  end

  private

  def companies_with_loyalty_data
    company_ids = current_user.loyalty_points.select(:company_id).distinct
    companies = Company.where(id: company_ids)
                       .joins(:company_setting)
                       .where(company_settings: { loyalty_enabled: true })

    companies.map do |company|
      {
        company:  company,
        balance:  LoyaltyPoint.balance_for(current_user, company),
        threshold: company.company_setting.loyalty_points_threshold,
        usable_codes: current_user.discount_codes.where(company: company).usable.count
      }
    end
  end

  def placeholder_appointment(company)
    Appointment.new(company: company, client_user: current_user, status: :completed)
  end
end
