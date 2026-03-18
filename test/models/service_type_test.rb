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
end
