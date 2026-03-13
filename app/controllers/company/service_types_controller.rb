class Company::ServiceTypesController < Company::BaseController
  before_action :set_service_type, only: [:show, :edit, :update, :destroy, :toggle_active]

  def index
    @service_types = @company.service_types.order(:name)
  end

  def new
    @service_type = @company.service_types.new
  end

  def create
    @service_type = @company.service_types.new(service_type_params)
    if @service_type.save
      redirect_to company_service_types_path,
        notice: "Prestation \"#{@service_type.name}\" créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @service_type.update(service_type_params)
      redirect_to company_service_types_path,
        notice: "Prestation mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service_type.destroy
    redirect_to company_service_types_path, notice: "Prestation supprimée."
  end

  def toggle_active
    @service_type.update!(active: !@service_type.active)
    redirect_to company_service_types_path
  end

  private

  def set_service_type
    @service_type = @company.service_types.find(params[:id])
  end

  def service_type_params
    params.require(:service_type).permit(:name, :description, :duration_minutes,
                                          :price_cents, :active)
  end
end
