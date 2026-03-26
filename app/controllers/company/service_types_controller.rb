class Company::ServiceTypesController < Company::BaseController
  SERVICE_TEMPLATES = {
    "consultation_express" => {
      name: "Consultation express",
      description: "Diagnostic rapide et recommandations actionnables.",
      duration_minutes: 30,
      price_cents: 3500
    },
    "session_standard" => {
      name: "Session standard",
      description: "Prestation complete avec prise en charge standard.",
      duration_minutes: 60,
      price_cents: 6500
    },
    "pack_premium" => {
      name: "Pack premium",
      description: "Accompagnement prioritaire avec suivi personnalise.",
      duration_minutes: 90,
      price_cents: 9900
    },
    "controle_rapide" => {
      name: "Controle rapide",
      description: "Verification ciblee avec points de controle essentiels.",
      duration_minutes: 20,
      price_cents: 2500
    },
    "intervention_domicile" => {
      name: "Intervention a domicile",
      description: "Deplacement sur site avec resolution sur place.",
      duration_minutes: 75,
      price_cents: 8500
    }
  }.freeze

  before_action :set_service_type, only: [ :edit, :update, :destroy, :toggle_active ]

  def index
    @service_types = @company.service_types.order(:name)
  end

  def new
    @service_type = @company.service_types.new
    @service_templates = SERVICE_TEMPLATES
  end

  def create
    @service_type = @company.service_types.new(service_type_params)
    if @service_type.save
      redirect_to company_service_types_path,
        notice: "Prestation \"#{@service_type.name}\" créée."
    else
      @service_templates = SERVICE_TEMPLATES
      render :new, status: :unprocessable_entity
    end
  end

  def quick_create
    selected_keys = Array(params[:template_keys]).take(3)
    templates = selected_keys.filter_map { |key| SERVICE_TEMPLATES[key] }

    created_count = 0
    templates.each do |template|
      next if @company.service_types.exists?(name: template[:name])

      @company.service_types.create!(template.merge(active: true))
      created_count += 1
    end

    if created_count.positive?
      redirect_to company_service_types_path,
        notice: "#{created_count} prestation(s) ajoutee(s) via l'assistant."
    else
      redirect_to new_company_service_type_path,
        alert: "Selectionnez au moins un template non deja cree."
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
                                          :price_cents, :active, :deposit_kind, :deposit_value)
  end
end
