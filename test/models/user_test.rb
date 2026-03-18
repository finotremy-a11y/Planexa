require "test_helper"

class UserTest < ActiveSupport::TestCase
  # — Validations —
  test "invalid without first_name" do
    user = build(:user, first_name: "")
    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
  end

  test "invalid without last_name" do
    user = build(:user, last_name: "")
    assert_not user.valid?
    assert_includes user.errors[:last_name], "can't be blank"
  end

  test "invalid without email" do
    user = build(:user, email: nil)
    assert_not user.valid?
  end

  test "email must be unique" do
    existing = create(:user)
    duplicate = build(:user, email: existing.email)
    assert_not duplicate.valid?
    assert duplicate.errors[:email].any?
  end

  # — Enums —
  test "has correct role enum values" do
    assert_equal 0, User.roles[:client]
    assert_equal 1, User.roles[:company_admin]
    assert_equal 2, User.roles[:admin]
  end

  # — Methods —
  test "full_name retourne prénom + nom" do
    user = build(:user, first_name: "Jean", last_name: "Dupont")
    assert_equal "Jean Dupont", user.full_name
  end

  test "client? retourne true pour un client" do
    user = build(:user, role: :client)
    assert user.client?
  end

  test "company_admin? retourne true pour un company_admin" do
    user = build(:user, role: :company_admin)
    assert user.company_admin?
  end
end
