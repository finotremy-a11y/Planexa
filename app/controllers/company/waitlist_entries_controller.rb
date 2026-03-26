class Company::WaitlistEntriesController < Company::BaseController
  before_action :set_entry, only: [ :show, :destroy ]

  def index
    @q = @company.waitlist_entries.ransack(params[:q])
    @pagy, @entries = pagy(
      @q.result.includes(:service_type, :client_user).order(created_at: :desc)
    )
  end

  def show; end

  def destroy
    @entry.expire!
    redirect_to company_waitlist_entries_path, notice: "Inscription retirée de la liste d'attente."
  end

  private

  def set_entry
    @entry = @company.waitlist_entries.find(params[:id])
  end
end
