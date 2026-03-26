SitemapGenerator::Sitemap.default_host = "https://planifypro.fr"

SitemapGenerator::Sitemap.create do
  # Pages statiques
  add root_path,             changefreq: "weekly",  priority: 1.0
  add search_path,           changefreq: "daily",   priority: 0.9
  add tarifs_path,           changefreq: "monthly", priority: 0.8
  add cgu_path,              changefreq: "monthly", priority: 0.3
  add cgv_path,              changefreq: "monthly", priority: 0.3
  add confidentialite_path,  changefreq: "monthly", priority: 0.3
  add mentions_legales_path, changefreq: "monthly", priority: 0.3
  add contact_path,          changefreq: "monthly", priority: 0.5

  # Fiches entreprises publiques
  Company.active.find_each do |company|
    add company_public_path(company),
      lastmod:    company.updated_at,
      changefreq: "weekly",
      priority:   0.8
  end

  # Pages SEO catégorie × ville (générées dynamiquement depuis les données réelles)
  SEO_ACTIVITIES = %w[
    coiffeur coiffeuse barbier osteopathe kinesitherapeute
    medecin-generaliste dermatologue dentiste psychologue
    naturopathe sophrologue coach-sportif personal-trainer
    plombier electricien serrurier menage-a-domicile
    veterinaire podologue orthophoniste
  ]

  SEO_CITIES = Company.active.distinct.pluck(:city).compact.map(&:parameterize).uniq.first(40)

  SEO_ACTIVITIES.each do |activity|
    SEO_CITIES.each do |city|
      add seo_search_landing_path(activity_slug: activity, city_slug: city),
        changefreq: "weekly",
        priority:   0.7
    end
  end
end
