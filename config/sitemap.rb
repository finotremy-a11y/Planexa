SitemapGenerator::Sitemap.default_host = "https://planifypro.fr"

SitemapGenerator::Sitemap.create do
  # Pages statiques
  add root_path,             changefreq: "weekly",  priority: 1.0
  add search_path,           changefreq: "daily",   priority: 0.9
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
end
