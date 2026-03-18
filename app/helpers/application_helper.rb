module ApplicationHelper
  include Pagy::Frontend

  # ── SEO ─────────────────────────────────────────────────────────────────────

  def default_meta_description
    "Planify Pro — La plateforme de gestion de rendez-vous pour les artisans " \
    "et entreprises de services. Planning en ligne, réservations clients, " \
    "paiements sécurisés."
  end

  def page_title(title = nil)
    title.present? ? "#{title} — Planify Pro" : "Planify Pro — Gestion de rendez-vous pour professionnels"
  end

  def og_image_url
    "#{request.base_url}/og-image.png"
  end

  # ── Statuts ─────────────────────────────────────────────────────────────────

  def status_badge(status)
    map = {
      "pending"   => [ "badge-gold",  "En attente" ],
      "confirmed" => [ "badge-green", "Confirmé" ],
      "cancelled" => [ "badge-red",   "Annulé" ],
      "completed" => [ "badge-grey",  "Terminé" ],
      "no_show"   => [ "badge-red",   "Absent" ],
      "trialing"  => [ "badge-gold",  "Essai" ],
      "active"    => [ "badge-green", "Actif" ],
      "past_due"  => [ "badge-red",   "Impayé" ],
      "suspended" => [ "badge-red",   "Suspendu" ],
      "canceled"  => [ "badge-grey",  "Annulé" ]
    }
    css, label = map[status.to_s] || [ "badge-grey", status.to_s.humanize ]
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

  def legal_business_name
    ENV.fetch("LEGAL_BUSINESS_NAME", "Planify Pro")
  end

  def legal_owner_name
    ENV.fetch("LEGAL_OWNER_NAME", legal_business_name)
  end

  def legal_owner_siret
    ENV.fetch("LEGAL_OWNER_SIRET", "À configurer")
  end

  def legal_owner_address
    ENV.fetch("LEGAL_OWNER_ADDRESS", "Adresse à configurer")
  end

  def legal_contact_email
    ENV.fetch("EMAIL_CONTACT", ENV.fetch("LEGAL_CONTACT_EMAIL", "contact@planifypro.fr"))
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
    ENV.fetch("LEGAL_CITY", "Ville à configurer")
  end
end
