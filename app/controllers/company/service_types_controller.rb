class Company::ServiceTypesController < Company::BaseController
  TEMPLATES_BY_SECTOR = {
    standard_business: {
      "prestation_rapide" => {
        name: "Prestation rapide",
        description: "Intervention courte et ciblée pour une demande spécifique.",
        duration_minutes: 30,
        price_cents: 3500
      },
      "prestation_standard" => {
        name: "Prestation standard",
        description: "Prise en charge complète avec accompagnement personnalisé.",
        duration_minutes: 60,
        price_cents: 6500
      },
      "prestation_premium" => {
        name: "Prestation premium",
        description: "Accompagnement prioritaire avec suivi dédié avant et après.",
        duration_minutes: 90,
        price_cents: 9900
      },
      "diagnostic" => {
        name: "Diagnostic initial",
        description: "Évaluation complète de la situation avec recommandations détaillées.",
        duration_minutes: 45,
        price_cents: 5000
      },
      "intervention_domicile" => {
        name: "Intervention à domicile",
        description: "Déplacement sur site avec résolution directe sur place.",
        duration_minutes: 75,
        price_cents: 8500
      },
      "bilan_suivi" => {
        name: "Bilan de suivi",
        description: "Point de contrôle régulier pour assurer la continuité du service.",
        duration_minutes: 20,
        price_cents: 2500
      }
    },
    healthcare_professional: {
      "consultation_standard" => {
        name: "Consultation",
        description: "Consultation médicale standard avec examen clinique.",
        duration_minutes: 20,
        price_cents: 2500
      },
      "consultation_longue" => {
        name: "Consultation longue",
        description: "Consultation approfondie pour situation complexe ou premier avis.",
        duration_minutes: 45,
        price_cents: 5000
      },
      "consultation_urgence" => {
        name: "Consultation urgente",
        description: "Créneaux réservés aux situations nécessitant une prise en charge rapide.",
        duration_minutes: 15,
        price_cents: 2500
      },
      "bilan_sante" => {
        name: "Bilan de santé",
        description: "Bilan complet avec examens, résultats commentés et plan de suivi.",
        duration_minutes: 60,
        price_cents: 8000
      },
      "suivi_chronique" => {
        name: "Suivi maladie chronique",
        description: "Consultation de suivi pour patient en traitement long terme.",
        duration_minutes: 30,
        price_cents: 3000
      },
      "teleconsultation" => {
        name: "Téléconsultation",
        description: "Consultation à distance par vidéo. Lien envoyé par email après confirmation.",
        duration_minutes: 20,
        price_cents: 2500
      }
    }
  }.freeze

  before_action :set_service_type, only: [ :edit, :update, :destroy, :toggle_active ]

  def index
    @service_types = @company.service_types.order(:name)
  end

  def new
    @service_type = @company.service_types.new
    @service_templates = templates_for_company
  end

  def create
    @service_type = @company.service_types.new(service_type_params)
    if @service_type.save
      track_event("ajout_prestation", company: @company,
                  service_type_id: @service_type.id)
      redirect_to company_service_types_path,
        notice: "Prestation \"#{@service_type.name}\" créée."
    else
      @service_templates = templates_for_company
      render :new, status: :unprocessable_entity
    end
  end

  def quick_create
    available_templates = templates_for_company
    selected_keys = Array(params[:template_keys]).take(3)
    templates = selected_keys.filter_map { |key| available_templates[key] }

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
    deposit_was_inactive = !@service_type.deposit_required?

    if @service_type.update(service_type_params)
      if deposit_was_inactive && @service_type.deposit_required?
        track_event("activation_acompte", company: @company,
                    service_type_id: @service_type.id)
      end
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

  def templates_for_company
    sector = @company.professional_category.to_sym
    TEMPLATES_BY_SECTOR.fetch(sector, TEMPLATES_BY_SECTOR[:standard_business])
  end

  def service_type_params
    params.require(:service_type).permit(:name, :description, :duration_minutes,
                                          :price_cents, :active, :deposit_kind, :deposit_value)
  end
end
