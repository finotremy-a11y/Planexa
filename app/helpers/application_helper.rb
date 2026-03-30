module ApplicationHelper
  include Pagy::Frontend
  include Chartkick::Helper

  # ── SEO ─────────────────────────────────────────────────────────────────────

  def default_meta_description
    t("seo.default_meta_description")
  end

  def page_title(title = nil)
    title.present? ? "#{title} — Planexa" : t("seo.default_title")
  end

  def og_image_url
    "#{request.base_url}/og-image.png"
  end

  # ── Statuts ─────────────────────────────────────────────────────────────────

  def status_badge(status)
    map = {
      "pending" => "badge-gold",
      "confirmed" => "badge-green",
      "cancelled" => "badge-red",
      "completed" => "badge-grey",
      "no_show" => "badge-red",
      "trialing" => "badge-gold",
      "active" => "badge-green",
      "past_due" => "badge-red",
      "suspended" => "badge-red",
      "canceled" => "badge-grey"
    }

    css = map[status.to_s] || "badge-grey"
    label = t("statuses.#{status}", default: status.to_s.humanize)
    content_tag(:span, label, class: "badge #{css}")
  end

  def price_display(cents)
    return "Sur devis" if cents.to_i == 0
    number_to_currency(cents / 100.0, unit: "€", separator: ",",
                       delimiter: " ", format: "%n %u")
  end

  def duration_display(minutes)
    return "#{minutes} min" if minutes < 60
    hours = minutes / 60
    mins  = minutes % 60
    mins > 0 ? "#{hours}h#{format('%02d', mins)}" : "#{hours}h"
  end

  def avatar_initials(name)
    parts = name.to_s.split.first(2)
    parts.map { |p| p[0].upcase }.join
  end

  def locale_name(locale_code)
    t("locales.names.#{locale_code}", default: locale_code.to_s.upcase)
  end

  def locale_badge(locale_code)
    locale_code.to_s.upcase
  end

  def legal_business_name
    ENV["LEGAL_BUSINESS_NAME"].presence || "Planexa"
  end

  def legal_owner_name
    ENV["LEGAL_OWNER_NAME"].presence || legal_business_name
  end

  def legal_owner_siret
    ENV["LEGAL_OWNER_SIRET"].presence || "88300612400035"
  end

  def legal_owner_address
    ENV["LEGAL_OWNER_ADDRESS"].presence || "10 CHEMIN de la Fourniserie, 12410 Salles-Curan FRANCE"
  end

  def legal_contact_email
    ENV.fetch("EMAIL_CONTACT", ENV.fetch("LEGAL_CONTACT_EMAIL", "contact@planexa.fr"))
  end

  def legal_dpo_email
    ENV.fetch("LEGAL_DPO_EMAIL", legal_contact_email)
  end

  def legal_phone
    ENV["LEGAL_PHONE"].presence
  end

  def legal_updated_at
    ENV.fetch("LEGAL_UPDATED_AT", Date.current.strftime("%d/%m/%Y"))
  end

  def legal_city
    ENV["LEGAL_CITY"].presence || "Salles-Curan"
  end

  def company_local_business_schema_json(company, avg_rating: nil, review_count: nil)
    payload = {
      "@context" => "https://schema.org",
      "@type" => "LocalBusiness",
      "name" => company.name,
      "description" => company.description,
      "telephone" => company.phone,
      "url" => company.website.presence || request.original_url,
      "image" => company.logo_url,
      "address" => {
        "@type" => "PostalAddress",
        "streetAddress" => company.address,
        "addressLocality" => company.city,
        "postalCode" => company.zip_code,
        "addressCountry" => "FR"
      },
      "openingHoursSpecification" => company_opening_hours_specifications(company)
    }.compact

    if review_count.to_i.positive? && avg_rating.present?
      payload["aggregateRating"] = {
        "@type" => "AggregateRating",
        "ratingValue" => avg_rating,
        "reviewCount" => review_count
      }
    end

    payload.to_json
  end

  private

  def company_opening_hours_specifications(company)
    day_map = {
      0 => "Sunday",
      1 => "Monday",
      2 => "Tuesday",
      3 => "Wednesday",
      4 => "Thursday",
      5 => "Friday",
      6 => "Saturday"
    }

    company.schedules.available.recurring.group_by(&:day_of_week).map do |day_of_week, slots|
      next if day_of_week.nil?

      {
        "@type" => "OpeningHoursSpecification",
        "dayOfWeek" => "https://schema.org/#{day_map[day_of_week]}",
        "opens" => slots.min_by(&:start_time).start_time.strftime("%H:%M"),
        "closes" => slots.max_by(&:end_time).end_time.strftime("%H:%M")
      }
    end.compact.sort_by { |entry| entry["dayOfWeek"] }
  end
end
