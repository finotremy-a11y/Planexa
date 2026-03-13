# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
puts "🌱 Démarrage du seeding..."

# ── Admin ─────────────────────────────────────────────────────────────────────
admin = User.find_or_create_by(email: ENV.fetch("ADMIN_EMAIL", "admin@planifypro.fr")) do |u|
  u.password      = ENV.fetch("ADMIN_PASSWORD", "AdminPlanify2025!")
  u.first_name    = "Admin"
  u.last_name     = "Planify"
  u.role          = :admin
  u.confirmed_at  = Time.current
end
puts "✅ Admin créé : #{admin.email}"

# ── Entreprise de démo ────────────────────────────────────────────────────────
if Rails.env.development?
  company_user = User.find_or_create_by(email: "demo-entreprise@planifypro.fr") do |u|
    u.password     = "DemoEntreprise2025!"
    u.first_name   = "Jean"
    u.last_name    = "Dupont"
    u.role         = :company_admin
    u.confirmed_at = Time.current
  end

  company = Company.find_or_create_by(siret: "12345678901234") do |c|
    c.user        = company_user
    c.name        = "Plomberie Dupont & Fils"
    c.address     = "12 rue des Artisans"
    c.city        = "Lyon"
    c.zip_code    = "69001"
    c.phone       = "0478000000"
    c.description = "Plomberie, chauffage et sanitaire depuis 1985. Intervention rapide sur Lyon et agglomération."
    c.status      = :active
  end

  # Réglages
  company.setting.update!(
    booking_mode:    :booking_public,
    payment_mode:    :payment_external,
    assignment_mode: :assignment_automatic
  )

  # Prestations
  [
    { name: "Dépannage plomberie", duration_minutes: 60,  price_cents: 9000 },
    { name: "Installation chaudière", duration_minutes: 240, price_cents: 80000 },
    { name: "Débouchage canalisation", duration_minutes: 90, price_cents: 15000 },
    { name: "Réparation fuite", duration_minutes: 45, price_cents: 7500 }
  ].each do |attrs|
    company.service_types.find_or_create_by(name: attrs[:name]) do |st|
      st.duration_minutes = attrs[:duration_minutes]
      st.price_cents      = attrs[:price_cents]
    end
  end

  # Employés
  employee_data = [
    { first_name: "Pierre", last_name: "Martin", email: "pierre@plomberie-dupont.fr", phone: "0601000001" },
    { first_name: "Sophie", last_name: "Bernard", email: "sophie@plomberie-dupont.fr", phone: "0601000002" },
    { first_name: "Marc", last_name: "Lefèvre", email: "marc@plomberie-dupont.fr", phone: "0601000003" }
  ]

  employee_data.each do |attrs|
    emp = company.employees.find_or_create_by(email: attrs[:email]) do |e|
      e.first_name = attrs[:first_name]
      e.last_name  = attrs[:last_name]
      e.phone      = attrs[:phone]
    end

    # Assigner toutes les compétences à chaque employé (démo)
    company.service_types.each do |st|
      EmployeeSkill.find_or_create_by(employee: emp, service_type: st) do |es|
        es.level = :intermediate
      end
    end

    # Horaires récurrents : Lundi à Vendredi 8h-18h
    (1..5).each do |day|
      Schedule.find_or_create_by(employee: emp, company: company, day_of_week: day, schedule_type: "recurring") do |s|
        s.start_time = "08:00"
        s.end_time   = "18:00"
        s.available  = true
      end
    end
  end

  # Client de démo
  client = User.find_or_create_by(email: "client-demo@planifypro.fr") do |u|
    u.password     = "DemoClient2025!"
    u.first_name   = "Marie"
    u.last_name    = "Durand"
    u.role         = :client
    u.confirmed_at = Time.current
  end

  puts "✅ Entreprise démo : #{company.name}"
  puts "   └ #{company.employees.count} employés"
  puts "   └ #{company.service_types.count} prestations"
  puts "✅ Client démo : #{client.email}"
end

puts "\n🎉 Seeding terminé !"
puts "\nComptes disponibles :"
puts "  Admin       → admin@planifypro.fr / AdminPlanify2025!"
puts "  Entreprise  → demo-entreprise@planifypro.fr / DemoEntreprise2025!"
puts "  Client      → client-demo@planifypro.fr / DemoClient2025!"
