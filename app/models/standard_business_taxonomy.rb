class StandardBusinessTaxonomy
  SPECIALTIES = [
    # Construction et bâtiment
    "Plomberie",
    "Électricité",
    "Maçonnerie",
    "Charpenterie",
    "Couverture",
    "Menuiserie",
    "Peinture",
    "Carrelage",
    "Vitrerie",

    # Nettoyage et entretien
    "Nettoyage général",
    "Nettoyage professionnel",
    "Desinsectisation",
    "Traitement antitermites",
    "Jardinage et paysagisme",
    "Élagage",

    # Automobile
    "Mécanique automobile",
    "Carrosserie",
    "Peinture automobile",
    "Électricité automobile",
    "Pneumatique",

    # Services à domicile
    "Dépannage rapide",
    "Plomberie d'urgence",
    "Débouchage",
    "Chauffagiste",
    "Serrurerie",
    "Fermetures et portes",
    "Isolation thermique",
    "Climatisation",

    # Informatique et électronique
    "Informatique",
    "Assistance informatique",
    "Maintenance informatique",
    "Dépannage électronique",
    "Installation réseau",

    # Services professionnels
    "Comptabilité",
    "Expertise comptable",
    "Conseil juridique",
    "Ressources humaines",
    "Formation professionnelle",
    "Conseil en gestion",

    # Immobilier
    "Immobilier",
    "Agence immobilière",
    "Évaluation immobilière",

    # Événementiel et restauration
    "Traiteur",
    "Boulangerie",
    "Pâtisserie",
    "Restauration",
    "Événementiel",
    "Décoration intérieure",
    "Fleuriste",

    # Coiffure et beauté
    "Coiffure",
    "Barbershop",
    "Salon de beauté",
    "Esthétique",
    "Manucure",
    "Pédicure",
    "Massage",

    # Bien-être et fitness
    "Fitness",
    "Coach sportif",
    "Yoga",
    "Pilates",
    "Boxe",
    "Danse",
    "Nutrition",

    # Éducation et loisirs
    "Cours particuliers",
    "Soutien scolaire",
    "Langue étrangère",
    "Musique",
    "Danse",
    "Arts plastiques",
    "Photographie",

    # Traduction et communication
    "Traduction",
    "Interprétation",
    "Rédaction",
    "Community management",
    "Graphisme",
    "Design web",
    "Marketing",

    # Animaux
    "Toilettage",
    "Dressage canin",
    "Promenade de chiens",
    "Pension pour animaux",
    "Éducation animale",

    # Services divers
    "Déménagement",
    "Logistique",
    "Transport",
    "Location",
    "Maintenance générale",
    "Réparation",
    "Restauration d'objets"
  ].freeze

  def self.specialties
    SPECIALTIES
  end

  def self.specialties_by_category
    {
      "Construction & Bâtiment" => [
        "Plomberie",
        "Électricité",
        "Maçonnerie",
        "Charpenterie",
        "Couverture",
        "Menuiserie",
        "Peinture",
        "Carrelage",
        "Vitrerie"
      ],
      "Nettoyage & Entretien" => [
        "Nettoyage général",
        "Nettoyage professionnel",
        "Desinsectisation",
        "Traitement antitermites",
        "Jardinage et paysagisme",
        "Élagage"
      ],
      "Automobile" => [
        "Mécanique automobile",
        "Carrosserie",
        "Peinture automobile",
        "Électricité automobile",
        "Pneumatique"
      ],
      "Services à Domicile" => [
        "Dépannage rapide",
        "Plomberie d'urgence",
        "Débouchage",
        "Chauffagiste",
        "Serrurerie",
        "Fermetures et portes",
        "Isolation thermique",
        "Climatisation"
      ],
      "Informatique & Électronique" => [
        "Informatique",
        "Assistance informatique",
        "Maintenance informatique",
        "Dépannage électronique",
        "Installation réseau"
      ],
      "Services Professionnels" => [
        "Comptabilité",
        "Expertise comptable",
        "Conseil juridique",
        "Ressources humaines",
        "Formation professionnelle",
        "Conseil en gestion"
      ],
      "Immobilier" => [
        "Immobilier",
        "Agence immobilière",
        "Évaluation immobilière"
      ],
      "Événementiel & Restauration" => [
        "Traiteur",
        "Boulangerie",
        "Pâtisserie",
        "Restauration",
        "Événementiel",
        "Décoration intérieure",
        "Fleuriste"
      ],
      "Coiffure & Beauté" => [
        "Coiffure",
        "Barbershop",
        "Salon de beauté",
        "Esthétique",
        "Manucure",
        "Pédicure",
        "Massage"
      ],
      "Bien-être & Fitness" => [
        "Fitness",
        "Coach sportif",
        "Yoga",
        "Pilates",
        "Boxe",
        "Danse",
        "Nutrition"
      ],
      "Éducation & Loisirs" => [
        "Cours particuliers",
        "Soutien scolaire",
        "Langue étrangère",
        "Musique",
        "Danse",
        "Arts plastiques",
        "Photographie"
      ],
      "Traduction & Communication" => [
        "Traduction",
        "Interprétation",
        "Rédaction",
        "Community management",
        "Graphisme",
        "Design web",
        "Marketing"
      ],
      "Animaux" => [
        "Toilettage",
        "Dressage canin",
        "Promenade de chiens",
        "Pension pour animaux",
        "Éducation animale"
      ],
      "Services Divers" => [
        "Déménagement",
        "Logistique",
        "Transport",
        "Location",
        "Maintenance générale",
        "Réparation",
        "Restauration d'objets"
      ]
    }
  end
end
