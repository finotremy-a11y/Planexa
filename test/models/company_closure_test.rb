require "test_helper"

class CompanyClosureTest < ActiveSupport::TestCase
  test "valide avec un intervalle coherent" do
    closure = build(:company_closure)
    assert closure.valid?
  end

  test "invalide si la fin est avant le debut" do
    closure = build(:company_closure, starts_at: Time.current, ends_at: 1.hour.ago)
    assert_not closure.valid?
    assert_includes closure.errors[:ends_at], "doit etre apres la date de debut"
  end

  test "scope covering retourne les fermetures qui couvrent le creneau" do
    closure = create(:company_closure,
      starts_at: Time.zone.parse("2026-03-25 09:00"),
      ends_at: Time.zone.parse("2026-03-25 12:00"))

    results = CompanyClosure.covering(Time.zone.parse("2026-03-25 10:00"), Time.zone.parse("2026-03-25 11:00"))

    assert_includes results, closure
  end
end
