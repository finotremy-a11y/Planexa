# db/seeds.rb — Seed Complet Planify Pro
# ============================================================
# Lance avec : rails db:seed
# Réinitialise tout : rails db:seed:replant
#
# COMPTES DE TEST CRÉÉS :
# ─────────────────────────────────────────────────────────────
# ADMIN
#   admin@planifypro.fr          / AdminPlanify2025!
#
# ENTREPRISES (toutes avec abonnement actif)
#   plomberie@dupont.fr          / Password123!   → Plomberie Dupont & Fils
#   electricite@martin.fr        / Password123!   → Électricité Martin Pro
#   jardinage@verde.fr           / Password123!   → Verde Jardins & Espaces Verts
#   nettoyage@sparkle.fr         / Password123!   → Sparkle Nettoyage Pro
#   menuiserie@lebois.fr         / Password123!   → Menuiserie Le Bois Dormant
#
# CLIENTS
#   marie.durand@test.fr         / Password123!
#   thomas.bernard@test.fr       / Password123!
#   sophie.leroy@test.fr         / Password123!
#   lucas.moreau@test.fr         / Password123!
#   emma.petit@test.fr           / Password123!
# ─────────────────────────────────────────────────────────────

puts "\n🌱 Démarrage du seed complet Planify Pro..."
puts "=" * 55

# ── Nettoyage (ordre important pour les FK) ───────────────────
puts "\n🗑  Nettoyage de la base..."
Payment.destroy_all
Appointment.destroy_all
EmployeeSkill.destroy_all
Schedule.destroy_all
Employee.destroy_all
ServiceType.destroy_all
CompanySetting.destroy_all
Subscription.destroy_all
Company.destroy_all
User.destroy_all
puts "   ✓ Base nettoyée"

# ═══════════════════════════════════════════════════════════════
# ADMIN
# ═══════════════════════════════════════════════════════════════
puts "\n👑 Création du compte admin..."

admin_email = ENV.fetch("ADMIN_EMAIL", "admin@planifypro.fr").to_s.downcase.strip
admin_password = ENV.fetch("ADMIN_PASSWORD", "AdminPlanify2025!").to_s

admin = User.create!(
  first_name:   "Admin",
  last_name:    "Planify",
  email:        admin_email,
  password:     admin_password,
  role:         :admin,
  confirmed_at: Time.current
)
puts "   ✓ #{admin.email} (admin)"

# ═══════════════════════════════════════════════════════════════
# CLIENTS
# ═══════════════════════════════════════════════════════════════
puts "\n👤 Création des clients..."

clients_data = [
  { first_name: "Marie",   last_name: "Durand",  email: "marie.durand@test.fr",   phone: "06 11 22 33 44" },
  { first_name: "Thomas",  last_name: "Bernard",  email: "thomas.bernard@test.fr", phone: "06 22 33 44 55" },
  { first_name: "Sophie",  last_name: "Leroy",    email: "sophie.leroy@test.fr",   phone: "06 33 44 55 66" },
  { first_name: "Lucas",   last_name: "Moreau",   email: "lucas.moreau@test.fr",   phone: "06 44 55 66 77" },
  { first_name: "Emma",    last_name: "Petit",    email: "emma.petit@test.fr",     phone: "06 55 66 77 88" }
]

clients = clients_data.map do |data|
  client = User.create!(
    first_name:   data[:first_name],
    last_name:    data[:last_name],
    email:        data[:email],
    phone:        data[:phone],
    password:     "Password123!",
    role:         :client,
    confirmed_at: Time.current
  )
  puts "   ✓ #{client.full_name} (#{client.email})"
  client
end

# ═══════════════════════════════════════════════════════════════
# ENTREPRISE 1 — Plomberie Dupont & Fils
# Mode : réservation publique, paiement externe, assignation auto
# ═══════════════════════════════════════════════════════════════
puts "\n🏢 Création Plomberie Dupont & Fils..."

user_plomberie = User.create!(
  first_name:   "Jean",
  last_name:    "Dupont",
  email:        "plomberie@dupont.fr",
  password:     "Password123!",
  role:         :company_admin,
  confirmed_at: Time.current
)

plomberie = Company.create!(
  user:        user_plomberie,
  name:        "Plomberie Dupont & Fils",
  siret:       "12345678901234",
  address:     "12 rue des Artisans",
  city:        "Lyon",
  zip_code:    "69001",
  phone:       "04 78 12 34 56",
  description: "Plomberie, chauffage et sanitaire depuis 1985. Intervention rapide sur Lyon et l'agglomération. Devis gratuit, urgences 7j/7.",
  status:      :active
)

plomberie.company_setting.update!(
  booking_mode:    :booking_public,
  payment_mode:    :payment_external,
  assignment_mode: :assignment_automatic
)

Subscription.create!(
  company:                plomberie,
  stripe_subscription_id: "sub_plomberie_test_001",
  stripe_price_id:        ENV.fetch("STRIPE_PRICE_ID", "price_test"),
  status:                 :active,
  current_period_end:     30.days.from_now
)

# Prestations Plomberie
plomb_services = [
  { name: "Dépannage plomberie",       duration_minutes: 60,  price_cents: 9000,  description: "Intervention rapide pour toute panne plomberie" },
  { name: "Installation chaudière",    duration_minutes: 240, price_cents: 120000, description: "Pose et mise en service de chaudière gaz ou fioul" },
  { name: "Débouchage canalisation",   duration_minutes: 90,  price_cents: 15000, description: "Débouchage haute pression, caméra incluse" },
  { name: "Réparation fuite",          duration_minutes: 45,  price_cents: 7500,  description: "Détection et réparation de fuite" },
  { name: "Installation salle de bain", duration_minutes: 480, price_cents: 80000, description: "Rénovation complète salle de bain" }
]

plomb_service_objects = plomb_services.map do |s|
  ServiceType.create!(company: plomberie, **s, active: true)
end

# Employés Plomberie
plomb_employees_data = [
  { first_name: "Pierre",  last_name: "Martin",  email: "pierre.martin@plomberie-dupont.fr",  phone: "06 70 11 22 33" },
  { first_name: "Sophie",  last_name: "Bernard", email: "sophie.bernard@plomberie-dupont.fr", phone: "06 70 22 33 44" },
  { first_name: "Marc",    last_name: "Lefèvre", email: "marc.lefevre@plomberie-dupont.fr",   phone: "06 70 33 44 55" }
]

plomb_employees = plomb_employees_data.map do |e|
  Employee.create!(company: plomberie, **e, active: true)
end

# Aptitudes — tous les employés savent tout faire
plomb_employees.each do |emp|
  plomb_service_objects.each do |st|
    EmployeeSkill.create!(employee: emp, service_type: st, level: :intermediate)
  end
end

# Horaires récurrents — Lun-Ven 8h-18h + Samedi 8h-12h
plomb_employees.each do |emp|
  (1..5).each do |day|
    Schedule.create!(employee: emp, company: plomberie, day_of_week: day,
                    start_time: "08:00", end_time: "18:00",
                    schedule_type: "recurring", available: true)
  end
  Schedule.create!(employee: emp, company: plomberie, day_of_week: 6,
                  start_time: "08:00", end_time: "12:00",
                  schedule_type: "recurring", available: true)
end

puts "   ✓ #{plomberie.name} — #{plomb_employees.count} employés, #{plomb_service_objects.count} prestations"

# ═══════════════════════════════════════════════════════════════
# ENTREPRISE 2 — Électricité Martin Pro
# Mode : réservation publique, paiement IN-APP, assignation manuelle
# ═══════════════════════════════════════════════════════════════
puts "\n🏢 Création Électricité Martin Pro..."

user_elec = User.create!(
  first_name:   "Paul",
  last_name:    "Martin",
  email:        "electricite@martin.fr",
  password:     "Password123!",
  role:         :company_admin,
  confirmed_at: Time.current
)

electricite = Company.create!(
  user:        user_elec,
  name:        "Électricité Martin Pro",
  siret:       "23456789012345",
  address:     "8 avenue de la République",
  city:        "Paris",
  zip_code:    "75011",
  phone:       "01 43 12 34 56",
  description: "Électricien certifié RGE. Mise aux normes, installation domotique, dépannage toutes urgences sur Paris et sa banlieue.",
  status:      :active
)

electricite.company_setting.update!(
  booking_mode:    :booking_public,
  payment_mode:    :payment_in_app,
  assignment_mode: :assignment_manual
)

Subscription.create!(
  company:                electricite,
  stripe_subscription_id: "sub_electricite_test_002",
  stripe_price_id:        ENV.fetch("STRIPE_PRICE_ID", "price_test"),
  status:                 :trialing,
  trial_ends_at:          10.days.from_now,
  current_period_end:     30.days.from_now
)

elec_services = [
  { name: "Diagnostic électrique",      duration_minutes: 60,  price_cents: 8000,  description: "Bilan complet de votre installation" },
  { name: "Mise aux normes",            duration_minutes: 240, price_cents: 60000, description: "Mise en conformité tableau + circuits" },
  { name: "Installation domotique",     duration_minutes: 180, price_cents: 45000, description: "Volets roulants, éclairage connecté, alarme" },
  { name: "Dépannage électrique",       duration_minutes: 60,  price_cents: 9000,  description: "Intervention urgente, panne, court-circuit" },
  { name: "Pose prises & interrupteurs", duration_minutes: 90,  price_cents: 12000, description: "Ajout ou remplacement de points électriques" }
]

elec_service_objects = elec_services.map do |s|
  ServiceType.create!(company: electricite, **s, active: true)
end

elec_employees_data = [
  { first_name: "Antoine", last_name: "Dubois",   email: "antoine@electricite-martin.fr", phone: "06 80 11 22 33" },
  { first_name: "Claire",  last_name: "Fontaine", email: "claire@electricite-martin.fr",  phone: "06 80 22 33 44" }
]

elec_employees = elec_employees_data.map do |e|
  Employee.create!(company: electricite, **e, active: true)
end

elec_employees.each do |emp|
  elec_service_objects.each do |st|
    EmployeeSkill.create!(employee: emp, service_type: st, level: :expert)
  end
end

elec_employees.each do |emp|
  (1..5).each do |day|
    Schedule.create!(employee: emp, company: electricite, day_of_week: day,
                    start_time: "09:00", end_time: "17:30",
                    schedule_type: "recurring", available: true)
  end
end

puts "   ✓ #{electricite.name} — #{elec_employees.count} employés, #{elec_service_objects.count} prestations"

# ═══════════════════════════════════════════════════════════════
# ENTREPRISE 3 — Verde Jardins & Espaces Verts
# Mode : réservation publique, paiement externe, assignation auto
# ═══════════════════════════════════════════════════════════════
puts "\n🏢 Création Verde Jardins..."

user_jardinage = User.create!(
  first_name:   "Carlos",
  last_name:    "Verde",
  email:        "jardinage@verde.fr",
  password:     "Password123!",
  role:         :company_admin,
  confirmed_at: Time.current
)

jardinage = Company.create!(
  user:        user_jardinage,
  name:        "Verde Jardins & Espaces Verts",
  siret:       "34567890123456",
  address:     "3 chemin des Roses",
  city:        "Bordeaux",
  zip_code:    "33000",
  phone:       "05 56 12 34 56",
  description: "Entretien de jardins, création d'espaces verts, taille de haies et d'arbres. Intervention sur Bordeaux et le Médoc.",
  status:      :active
)

jardinage.company_setting.update!(
  booking_mode:    :booking_public,
  payment_mode:    :payment_external,
  assignment_mode: :assignment_automatic
)

Subscription.create!(
  company:                jardinage,
  stripe_subscription_id: "sub_jardinage_test_003",
  stripe_price_id:        ENV.fetch("STRIPE_PRICE_ID", "price_test"),
  status:                 :active,
  current_period_end:     15.days.from_now
)

jard_services = [
  { name: "Entretien jardin",      duration_minutes: 120, price_cents: 8000,  description: "Tonte, désherbage, soins des plantes" },
  { name: "Taille de haies",       duration_minutes: 180, price_cents: 12000, description: "Taille et ramassage des déchets verts inclus" },
  { name: "Création massif",       duration_minutes: 240, price_cents: 35000, description: "Conception et plantation d'un massif fleuri" },
  { name: "Abattage arbre",        duration_minutes: 300, price_cents: 55000, description: "Abattage, dessouchage et évacuation" },
  { name: "Gazon synthétique",     duration_minutes: 360, price_cents: 90000, description: "Fourniture et pose de gazon synthétique" }
]

jard_service_objects = jard_services.map do |s|
  ServiceType.create!(company: jardinage, **s, active: true)
end

jard_employees_data = [
  { first_name: "Miguel",  last_name: "Santos",  email: "miguel@verde-jardins.fr",  phone: "06 90 11 22 33" },
  { first_name: "Laura",   last_name: "Dupuis",  email: "laura@verde-jardins.fr",   phone: "06 90 22 33 44" },
  { first_name: "Kevin",   last_name: "Girard",  email: "kevin@verde-jardins.fr",   phone: "06 90 33 44 55" },
  { first_name: "Amandine", last_name: "Renault", email: "amandine@verde-jardins.fr", phone: "06 90 44 55 66" }
]

jard_employees = jard_employees_data.map do |e|
  Employee.create!(company: jardinage, **e, active: true)
end

# Aptitudes variées selon les employés
jard_employees[0..1].each do |emp|
  jard_service_objects.each { |st| EmployeeSkill.create!(employee: emp, service_type: st, level: :expert) }
end
jard_employees[2..3].each do |emp|
  jard_service_objects.first(3).each { |st| EmployeeSkill.create!(employee: emp, service_type: st, level: :intermediate) }
end

jard_employees.each do |emp|
  (1..6).each do |day|
    Schedule.create!(employee: emp, company: jardinage, day_of_week: day,
                    start_time: "07:30", end_time: "17:00",
                    schedule_type: "recurring", available: true)
  end
end

puts "   ✓ #{jardinage.name} — #{jard_employees.count} employés, #{jard_service_objects.count} prestations"

# ═══════════════════════════════════════════════════════════════
# ENTREPRISE 4 — Sparkle Nettoyage Pro
# Mode : réservation PRIVÉE, paiement externe, assignation manuelle
# ═══════════════════════════════════════════════════════════════
puts "\n🏢 Création Sparkle Nettoyage Pro..."

user_nettoyage = User.create!(
  first_name:   "Isabelle",
  last_name:    "Blanc",
  email:        "nettoyage@sparkle.fr",
  password:     "Password123!",
  role:         :company_admin,
  confirmed_at: Time.current
)

nettoyage = Company.create!(
  user:        user_nettoyage,
  name:        "Sparkle Nettoyage Pro",
  siret:       "45678901234567",
  address:     "22 rue du Commerce",
  city:        "Nantes",
  zip_code:    "44000",
  phone:       "02 40 12 34 56",
  description: "Nettoyage professionnel de locaux, remise en état après travaux, nettoyage de vitres. Contrats particuliers et entreprises.",
  status:      :active
)

nettoyage.company_setting.update!(
  booking_mode:    :booking_private,
  payment_mode:    :payment_external,
  assignment_mode: :assignment_manual
)

Subscription.create!(
  company:                nettoyage,
  stripe_subscription_id: "sub_nettoyage_test_004",
  stripe_price_id:        ENV.fetch("STRIPE_PRICE_ID", "price_test"),
  status:                 :active,
  current_period_end:     25.days.from_now
)

nett_services = [
  { name: "Nettoyage appartement",      duration_minutes: 120, price_cents: 9000,  description: "Ménage complet toutes pièces" },
  { name: "Nettoyage après travaux",    duration_minutes: 360, price_cents: 55000, description: "Dépoussièrement, nettoyage complet post-chantier" },
  { name: "Nettoyage de vitres",        duration_minutes: 90,  price_cents: 7000,  description: "Intérieur + extérieur, vitre et cadres" },
  { name: "Nettoyage de locaux pro",    duration_minutes: 180, price_cents: 18000, description: "Bureaux, salles de réunion, sanitaires" },
  { name: "Remise en état locatif",     duration_minutes: 240, price_cents: 35000, description: "État des lieux sortant, grand nettoyage" }
]

nett_service_objects = nett_services.map do |s|
  ServiceType.create!(company: nettoyage, **s, active: true)
end

nett_employees_data = [
  { first_name: "Fatou",   last_name: "Diallo",  email: "fatou@sparkle-pro.fr",   phone: "06 50 11 22 33" },
  { first_name: "Sylvie",  last_name: "Morin",   email: "sylvie@sparkle-pro.fr",  phone: "06 50 22 33 44" },
  { first_name: "Karim",   last_name: "Benzara", email: "karim@sparkle-pro.fr",   phone: "06 50 33 44 55" }
]

nett_employees = nett_employees_data.map do |e|
  Employee.create!(company: nettoyage, **e, active: true)
end

nett_employees.each do |emp|
  nett_service_objects.each { |st| EmployeeSkill.create!(employee: emp, service_type: st, level: :intermediate) }
  (1..5).each do |day|
    Schedule.create!(employee: emp, company: nettoyage, day_of_week: day,
                    start_time: "08:00", end_time: "16:00",
                    schedule_type: "recurring", available: true)
  end
end

puts "   ✓ #{nettoyage.name} — #{nett_employees.count} employés, #{nett_service_objects.count} prestations (mode privé)"

# ═══════════════════════════════════════════════════════════════
# ENTREPRISE 5 — Menuiserie Le Bois Dormant
# Mode : réservation publique, paiement externe, assignation auto
# Abonnement past_due pour tester la suspension
# ═══════════════════════════════════════════════════════════════
puts "\n🏢 Création Menuiserie Le Bois Dormant..."

user_menuiserie = User.create!(
  first_name:   "François",
  last_name:    "Lebois",
  email:        "menuiserie@lebois.fr",
  password:     "Password123!",
  role:         :company_admin,
  confirmed_at: Time.current
)

menuiserie = Company.create!(
  user:        user_menuiserie,
  name:        "Menuiserie Le Bois Dormant",
  siret:       "56789012345678",
  address:     "5 impasse des Chênes",
  city:        "Toulouse",
  zip_code:    "31000",
  phone:       "05 61 12 34 56",
  description: "Menuisier ébéniste depuis 20 ans. Fabrication sur mesure, pose de parquet, rénovation de meubles anciens.",
  status:      :active
)

menuiserie.company_setting.update!(
  booking_mode:    :booking_public,
  payment_mode:    :payment_external,
  assignment_mode: :assignment_automatic
)

# ⚠️ Abonnement past_due pour tester le flow de relance
Subscription.create!(
  company:                menuiserie,
  stripe_subscription_id: "sub_menuiserie_test_005",
  stripe_price_id:        ENV.fetch("STRIPE_PRICE_ID", "price_test"),
  status:                 :past_due,
  current_period_end:     3.days.ago
)

men_services = [
  { name: "Pose de parquet",       duration_minutes: 360, price_cents: 85000, description: "Fourniture et pose de parquet massif ou flottant" },
  { name: "Fabrication meuble",    duration_minutes: 480, price_cents: 150000, description: "Meuble sur mesure en bois massif" },
  { name: "Rénovation meuble",     duration_minutes: 240, price_cents: 45000, description: "Restauration et refinition de meubles anciens" },
  { name: "Pose de porte",         duration_minutes: 120, price_cents: 25000, description: "Pose de porte intérieure ou blindée" },
  { name: "Aménagement placard",   duration_minutes: 300, price_cents: 70000, description: "Dressing et rangements sur mesure" }
]

men_service_objects = men_services.map do |s|
  ServiceType.create!(company: menuiserie, **s, active: true)
end

men_employees_data = [
  { first_name: "Julien",  last_name: "Carpentier", email: "julien@lebois.fr",  phone: "06 60 11 22 33" },
  { first_name: "Maxime",  last_name: "Charpentier", email: "maxime@lebois.fr",  phone: "06 60 22 33 44" }
]

men_employees = men_employees_data.map do |e|
  Employee.create!(company: menuiserie, **e, active: true)
end

men_employees.each do |emp|
  men_service_objects.each { |st| EmployeeSkill.create!(employee: emp, service_type: st, level: :expert) }
  (1..5).each do |day|
    Schedule.create!(employee: emp, company: menuiserie, day_of_week: day,
                    start_time: "08:00", end_time: "17:00",
                    schedule_type: "recurring", available: true)
  end
end

puts "   ✓ #{menuiserie.name} — #{men_employees.count} employés, #{men_service_objects.count} prestations (⚠️ past_due)"

# ═══════════════════════════════════════════════════════════════
# RENDEZ-VOUS — Scénarios variés pour tout tester
# ═══════════════════════════════════════════════════════════════
puts "\n📅 Création des rendez-vous..."

marie, thomas, sophie, lucas, emma = clients

# ── RDV Plomberie ──────────────────────────────────────────────

# RDV confirmé dans le futur (avec client connecté)
rdv1 = Appointment.create!(
  company:         plomberie,
  client_user:     marie,
  employee:        plomb_employees[0],
  service_type:    plomb_service_objects[0], # Dépannage
  scheduled_at:    2.days.from_now.change(hour: 9, min: 0),
  duration_minutes: 60,
  status:          :confirmed,
  booking_source:  :online,
  client_notes:    "Fuite sous l'évier de cuisine, ça coule depuis 2 jours.",
  urgent:          false
)

# RDV en attente non assigné
rdv2 = Appointment.create!(
  company:         plomberie,
  client_user:     thomas,
  employee:        nil,
  service_type:    plomb_service_objects[2], # Débouchage
  scheduled_at:    3.days.from_now.change(hour: 14, min: 0),
  duration_minutes: 90,
  status:          :pending,
  booking_source:  :online,
  client_notes:    "WC bouché, rien ne passe.",
  urgent:          true
)

# RDV urgent en attente
rdv3 = Appointment.create!(
  company:         plomberie,
  client_user:     sophie,
  employee:        plomb_employees[1],
  service_type:    plomb_service_objects[3], # Réparation fuite
  scheduled_at:    1.days.from_now.change(hour: 11, min: 0),
  duration_minutes: 45,
  status:          :confirmed,
  booking_source:  :online,
  urgent:          true,
  client_notes:    "Fuite au niveau du compteur d'eau."
)

# RDV passé terminé
rdv4 = Appointment.create!(
  company:         plomberie,
  client_user:     marie,
  employee:        plomb_employees[0],
  service_type:    plomb_service_objects[0],
  scheduled_at:    5.days.ago.change(hour: 10, min: 0),
  duration_minutes: 60,
  status:          :completed,
  booking_source:  :online,
  internal_notes:  "RDV effectué. Joint changé sous l'évier."
)

# RDV annulé
rdv5 = Appointment.create!(
  company:         plomberie,
  client_user:     lucas,
  employee:        plomb_employees[2],
  service_type:    plomb_service_objects[1], # Chaudière
  scheduled_at:    1.days.ago.change(hour: 9, min: 0),
  duration_minutes: 240,
  status:          :cancelled,
  booking_source:  :online,
  cancellation_reason: "Client a reporté les travaux."
)

# RDV manuel (saisi par l'entreprise)
rdv6 = Appointment.create!(
  company:         plomberie,
  client_user:     nil,
  employee:        plomb_employees[0],
  service_type:    plomb_service_objects[4], # Salle de bain
  scheduled_at:    7.days.from_now.change(hour: 8, min: 0),
  duration_minutes: 480,
  status:          :confirmed,
  booking_source:  :manual,
  internal_notes:  "Client M. Rousseau — 06 12 34 56 78. Rénovation complète SDB."
)

puts "   ✓ #{6} RDV Plomberie Dupont (confirmed, pending, urgent, completed, cancelled, manual)"

# ── RDV Électricité ────────────────────────────────────────────

rdv7 = Appointment.create!(
  company:         electricite,
  client_user:     emma,
  employee:        elec_employees[0],
  service_type:    elec_service_objects[0], # Diagnostic
  scheduled_at:    4.days.from_now.change(hour: 10, min: 0),
  duration_minutes: 60,
  status:          :confirmed,
  booking_source:  :online,
  client_notes:    "Appartement acheté en 1975, jamais remis aux normes."
)

rdv8 = Appointment.create!(
  company:         electricite,
  client_user:     thomas,
  employee:        nil, # Non assigné — mode manuel
  service_type:    elec_service_objects[3], # Dépannage
  scheduled_at:    1.days.from_now.change(hour: 15, min: 0),
  duration_minutes: 60,
  status:          :pending,
  booking_source:  :online,
  urgent:          true,
  client_notes:    "Plus de courant dans la chambre depuis ce matin."
)

rdv9 = Appointment.create!(
  company:         electricite,
  client_user:     sophie,
  employee:        elec_employees[1],
  service_type:    elec_service_objects[1], # Mise aux normes
  scheduled_at:    10.days.from_now.change(hour: 9, min: 0),
  duration_minutes: 240,
  status:          :confirmed,
  booking_source:  :online
)

puts "   ✓ #{3} RDV Électricité Martin"

# ── RDV Jardinage ──────────────────────────────────────────────

rdv10 = Appointment.create!(
  company:         jardinage,
  client_user:     lucas,
  employee:        jard_employees[0],
  service_type:    jard_service_objects[0], # Entretien
  scheduled_at:    3.days.from_now.change(hour: 8, min: 0),
  duration_minutes: 120,
  status:          :confirmed,
  booking_source:  :online,
  client_notes:    "Grand jardin de 400m², tonte + désherbage allées."
)

rdv11 = Appointment.create!(
  company:         jardinage,
  client_user:     marie,
  employee:        jard_employees[1],
  service_type:    jard_service_objects[1], # Taille haies
  scheduled_at:    6.days.from_now.change(hour: 9, min: 0),
  duration_minutes: 180,
  status:          :pending,
  booking_source:  :online
)

rdv12 = Appointment.create!(
  company:         jardinage,
  client_user:     emma,
  employee:        jard_employees[0],
  service_type:    jard_service_objects[0],
  scheduled_at:    10.days.ago.change(hour: 8, min: 0),
  duration_minutes: 120,
  status:          :completed,
  booking_source:  :online,
  internal_notes:  "Client très satisfait. Prévoir entretien mensuel."
)

puts "   ✓ #{3} RDV Verde Jardins"

# ── RDV Nettoyage (mode privé — tous manuels) ─────────────────

rdv13 = Appointment.create!(
  company:         nettoyage,
  client_user:     nil,
  employee:        nett_employees[0],
  service_type:    nett_service_objects[0], # Appart
  scheduled_at:    2.days.from_now.change(hour: 9, min: 0),
  duration_minutes: 120,
  status:          :confirmed,
  booking_source:  :manual,
  internal_notes:  "Mme Lambert — 06 23 45 67 89 — Appartement 65m², 3ème étage."
)

rdv14 = Appointment.create!(
  company:         nettoyage,
  client_user:     nil,
  employee:        nett_employees[1],
  service_type:    nett_service_objects[3], # Locaux pro
  scheduled_at:    5.days.from_now.change(hour: 7, min: 0),
  duration_minutes: 180,
  status:          :confirmed,
  booking_source:  :manual,
  internal_notes:  "Cabinet médical Dr Rousseau — tous les vendredis matins."
)

puts "   ✓ #{2} RDV Sparkle Nettoyage (mode privé)"

# ── RDV Menuiserie ─────────────────────────────────────────────

rdv15 = Appointment.create!(
  company:         menuiserie,
  client_user:     thomas,
  employee:        men_employees[0],
  service_type:    men_service_objects[0], # Parquet
  scheduled_at:    8.days.from_now.change(hour: 8, min: 0),
  duration_minutes: 360,
  status:          :confirmed,
  booking_source:  :online,
  client_notes:    "Salon 35m², parquet chêne massif."
)

puts "   ✓ #{1} RDV Menuiserie Le Bois Dormant"

# ═══════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════════════

total_rdv = Appointment.count

puts "\n" + "=" * 55
puts "🎉 Seed terminé avec succès !"
puts "=" * 55

puts "\n📊 Résumé :"
puts "   #{User.admin.count} admin"
puts "   #{Company.count} entreprises"
puts "   #{User.client.count} clients"
puts "   #{Employee.count} employés"
puts "   #{ServiceType.count} prestations"
puts "   #{Appointment.count} rendez-vous"
puts "     ↳ #{Appointment.confirmed.count} confirmés"
puts "     ↳ #{Appointment.pending.count} en attente"
puts "     ↳ #{Appointment.completed.count} terminés"
puts "     ↳ #{Appointment.cancelled.count} annulés"
puts "   #{Subscription.count} abonnements"
puts "     ↳ #{Subscription.active.count} actifs"
puts "     ↳ #{Subscription.trialing.count} en essai"
puts "     ↳ #{Subscription.past_due.count} impayé(s) ⚠️"

puts "\n🔑 Comptes de connexion :"
puts "\n  👑 ADMIN"
puts "     #{admin_email}  /  #{admin_password}"

puts "\n  🏢 ENTREPRISES  (mot de passe : Password123!)"
puts "     plomberie@dupont.fr      → Plomberie Dupont    (public, externe, auto)"
puts "     electricite@martin.fr    → Électricité Martin  (public, in-app, manuel) ⚡ essai"
puts "     jardinage@verde.fr       → Verde Jardins       (public, externe, auto)"
puts "     nettoyage@sparkle.fr     → Sparkle Nettoyage   (PRIVÉ, externe, manuel)"
puts "     menuiserie@lebois.fr     → Le Bois Dormant     (public, externe, auto) ⚠️ impayé"

puts "\n  👤 CLIENTS  (mot de passe : Password123!)"
puts "     marie.durand@test.fr     → Marie Durand   (2 RDV dont 1 terminé)"
puts "     thomas.bernard@test.fr   → Thomas Bernard (3 RDV dont 1 urgent)"
puts "     sophie.leroy@test.fr     → Sophie Leroy   (2 RDV)"
puts "     lucas.moreau@test.fr     → Lucas Moreau   (2 RDV)"
puts "     emma.petit@test.fr       → Emma Petit     (2 RDV)"

puts "\n  🧪 CE QUE TU PEUX TESTER :"
puts "     ✓ Dashboard entreprise avec stats et RDV à venir"
puts "     ✓ RDV en attente non assigné (plomberie + électricité)"
puts "     ✓ RDV urgent (plomberie)"
puts "     ✓ Mode réservation privée (Sparkle Nettoyage)"
puts "     ✓ Paiement in-app activé (Électricité Martin)"
puts "     ✓ Assignation manuelle d'employé (Électricité Martin)"
puts "     ✓ Abonnement en essai (Électricité Martin)"
puts "     ✓ Abonnement impayé + relance (Menuiserie Lebois)"
puts "     ✓ Dashboard client avec historique"
puts "     ✓ Dashboard admin avec KPIs réels"
puts "     ✓ Vue calendrier avec RDV répartis sur le mois"
puts "\n"
