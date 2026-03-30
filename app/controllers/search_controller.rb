class SearchController < ApplicationController
  skip_before_action :authenticate_user!
  include Pagy::Backend

  BUSINESS_SPECIALTIES = [
    "Coiffure",
    "Barbier",
    "Esthetique",
    "Massage bien-etre",
    "Onglerie",
    "Maquillage",
    "Tatouage",
    "Photographie",
    "Coaching sportif",
    "Yoga",
    "Nutrition",
    "Naturopathie",
    "Sophrologie",
    "Kinesitherapie",
    "Osteopathie",
    "Psychologie",
    "Orthophonie",
    "Podologie",
    "Dentaire",
    "Plomberie",
    "Electricite",
    "Peinture",
    "Menuiserie",
    "Serrurerie",
    "Climatisation",
    "Chauffage",
    "Nettoyage",
    "Jardinage",
    "Demoussage",
    "Mecanique auto",
    "Controle technique",
    "Lavage auto",
    "Reparation smartphone",
    "Informatique",
    "Cours particuliers",
    "Soutien scolaire",
    "Traduction",
    "Comptabilite",
    "Conseil juridique",
    "Immobilier",
    "Architecture",
    "Decoration interieure",
    "Evenementiel",
    "Traiteur",
    "Boulangerie",
    "Patisserie",
    "Toilettage",
    "Dressage canin"
  ].freeze

  def index
    scope = Company.active.with_public_booking.includes(:service_types, :company_setting)
    @specialty_options = specialty_options

    if params[:name].present?
      scope = scope.where("companies.name ILIKE ?", "%#{params[:name]}%")
    end

    if params[:activity].present?
      scope = scope.joins(:service_types)
                   .where("service_types.name ILIKE ?", "%#{params[:activity]}%")
                   .distinct
    end

    if params[:specialty].present?
      specialty_term = "%#{params[:specialty]}%"
      scope = scope.left_outer_joins(:service_types)
                   .where("companies.health_specialty ILIKE :term OR service_types.name ILIKE :term", term: specialty_term)
                   .distinct
    end

    if params[:max_price].present?
      scope = scope.joins(:service_types)
                   .where("service_types.price_cents <= ?", params[:max_price].to_i * 100)
                   .distinct
    end

    if params[:urgent] == "1"
      scope = scope.available_urgently
    end

    if params[:city].present?
      scope = scope.where("city ILIKE ?", "%#{params[:city]}%")
    end

    @pagy, @companies = pagy(scope)
    @company_review_stats = company_review_stats(@companies)
    @search_params = params.permit(:name, :activity, :specialty, :max_price, :urgent, :city)
  end

  def landing
    @activity = normalize_slug_phrase(params[:activity_slug])
    @city = normalize_slug_phrase(params[:city_slug])

    scope = Company.active.with_public_booking.includes(:service_types, :company_setting)
    scope = scope.where("companies.city ILIKE ?", "%#{@city}%") if @city.present?

    if @activity.present?
      scope = scope.joins(:service_types)
                   .where("service_types.name ILIKE ?", "%#{@activity}%")
                   .distinct
    end

    @pagy, @companies = pagy(scope)
    @company_review_stats = company_review_stats(@companies)
    @popular_services = @companies.flat_map { |company| company.service_types.active.limit(3).pluck(:name) }
                                  .uniq
                                  .first(8)
  end

  private

  def normalize_slug_phrase(value)
    CGI.unescape(value.to_s).tr("-", " ").squish
  end

  def company_review_stats(companies)
    company_ids = companies.map(&:id)
    return {} if company_ids.empty?

    Review.published
          .where(company_id: company_ids)
          .group(:company_id)
          .pluck(
            :company_id,
            Arel.sql("ROUND(AVG(rating)::numeric, 1)"),
            Arel.sql("COUNT(*)")
          )
          .each_with_object({}) do |(company_id, avg_rating, review_count), acc|
            acc[company_id] = {
              avg_rating: avg_rating.to_f,
              review_count: review_count.to_i
            }
          end
  end

  def specialty_options
    medical_specialties = MedicalTaxonomy.specialties
    configured_health_specialties = Company.active
                                          .with_public_booking
                                          .where.not(health_specialty: [ nil, "" ])
                                          .distinct
                                          .pluck(:health_specialty)
    service_specialties = ServiceType.active
                                   .joins(:company)
                                   .merge(Company.active.with_public_booking)
                                   .where.not(name: [ nil, "" ])
                                   .distinct
                                   .pluck(:name)

    (BUSINESS_SPECIALTIES + medical_specialties + configured_health_specialties + service_specialties)
      .map(&:strip)
      .reject(&:blank?)
      .uniq
      .sort_by(&:downcase)
  end
end
