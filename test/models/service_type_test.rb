require "test_helper"

class ServiceTypeTest < ActiveSupport::TestCase
  # — Validations —
  test "invalide sans name" do
    st = build(:service_type, name: nil)
    assert_not st.valid?
    assert st.errors[:name].any?
  end

  test "invalide sans duration_minutes" do
    st = build(:service_type, duration_minutes: nil)
    assert_not st.valid?
    assert st.errors[:duration_minutes].any?
  end

  test "invalide si duration_minutes est zéro" do
    st = build(:service_type, duration_minutes: 0)
    assert_not st.valid?
  end

  test "invalide si price_cents est négatif" do
    st = build(:service_type, price_cents: -100)
    assert_not st.valid?
  end

  test "valide avec price_cents à zéro (prestation gratuite)" do
    st = build(:service_type, price_cents: 0)
    assert st.valid?
  end

  test "valide avec attributs corrects" do
    st = build(:service_type)
    assert st.valid?
  end

  # — Scopes —
  test "scope active ne retourne que les prestations actives" do
    active   = create(:service_type, active: true)
    inactive = create(:service_type, active: false)
    assert_includes ServiceType.active, active
    assert_not_includes ServiceType.active, inactive
  end

  # — Associations —
  test "appartient à une company" do
    st = create(:service_type)
    assert_not_nil st.company
  end

  test "a plusieurs employee_skills" do
    st = create(:service_type)
    assert_respond_to st, :employee_skills
  end

  test "a plusieurs appointments" do
    st = create(:service_type)
    assert_respond_to st, :appointments
  end

  test "calcule un acompte fixe" do
    st = create(:service_type, price_cents: 9000, deposit_kind: :deposit_fixed_cents, deposit_value: 3000)

    assert st.deposit_required?
    assert_equal 3000, st.deposit_amount_cents
  end

  test "calcule un acompte en pourcentage" do
    st = create(:service_type, price_cents: 8000, deposit_kind: :deposit_percentage, deposit_value: 25)

    assert st.deposit_required?
    assert_equal 2000, st.deposit_amount_cents
  end

  test "invalide un pourcentage d'acompte hors bornes" do
    st = build(:service_type, deposit_kind: :deposit_percentage, deposit_value: 120)

    assert_not st.valid?
    assert st.errors[:deposit_value].any?
  end
end
