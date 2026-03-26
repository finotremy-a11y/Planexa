class Company::ApiTokensController < Company::BaseController
  before_action :set_api_token, only: :destroy

  def index
    @api_tokens = @company.api_tokens.order(created_at: :desc)
  end

  def create
    scopes = Array(params[:scopes]).reject(&:blank?)
    expires_at = params[:expires_at].presence

    token, plaintext = ApiToken.issue!(
      company: @company,
      name: params[:name].presence || "Token API",
      scopes: scopes,
      expires_at: expires_at
    )

    flash[:notice] = "Token API créé avec succès. Copiez-le maintenant : #{plaintext}"
    redirect_to company_api_tokens_path
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.record.errors.full_messages.join(", ")
    redirect_to company_api_tokens_path, status: :unprocessable_entity
  end

  def destroy
    @api_token.destroy!
    redirect_to company_api_tokens_path, notice: "Token API supprimé."
  end

  private

  def set_api_token
    @api_token = @company.api_tokens.find(params[:id])
  end
end
