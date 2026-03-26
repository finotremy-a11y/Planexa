class MedicalTaxonomy
  SPECIALTIES = [
    "Medecine generale",
    "Cardiologie",
    "Dermatologie",
    "Gynecologie",
    "Ophtalmologie",
    "Pediatrie",
    "Psychiatrie",
    "Osteopathie",
    "Psychologie",
    "Kinesitherapie",
    "Orthophonie",
    "Podologie",
    "Dentaire"
  ].freeze

  CONSULTATION_REASONS = {
    "Medecine generale" => [
      "Consultation de suivi",
      "Certificat medical",
      "Renouvellement d'ordonnance"
    ],
    "Kinesitherapie" => [
      "Douleur musculaire",
      "Reeducation post-traumatique",
      "Bilan fonctionnel"
    ],
    "Psychologie" => [
      "Entretien initial",
      "Suivi therapeutique",
      "Gestion du stress"
    ],
    "Dentaire" => [
      "Controle annuel",
      "Soin carie",
      "Urgence dentaire"
    ]
  }.freeze

  def self.specialties
    SPECIALTIES
  end

  def self.consultation_reasons_for(specialty)
    CONSULTATION_REASONS.fetch(specialty.to_s, [])
  end
end
