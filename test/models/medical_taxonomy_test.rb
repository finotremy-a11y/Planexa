require "test_helper"

class MedicalTaxonomyTest < ActiveSupport::TestCase
  test "expose une liste de specialites" do
    assert_includes MedicalTaxonomy.specialties, "Psychologie"
    assert_includes MedicalTaxonomy.specialties, "Osteopathie"
  end

  test "retourne des motifs de consultation par specialite" do
    reasons = MedicalTaxonomy.consultation_reasons_for("Psychologie")

    assert reasons.any?
    assert_includes reasons, "Entretien initial"
  end

  test "retourne une liste vide pour une specialite inconnue" do
    assert_equal [], MedicalTaxonomy.consultation_reasons_for("Inconnue")
  end
end
