require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  # — Validations —
  test "invalid without stripe_subscription_id" do
    sub = build(:subscription, stripe_subscription_id: nil)
    assert_not sub.valid?
    assert sub.errors[:stripe_subscription_id].any?
  end

  test "stripe_subscription_id must be unique" do
    existing = create(:subscription)
    duplicate = build(:subscription, stripe_subscription_id: existing.stripe_subscription_id)
    assert_not duplicate.valid?
    assert duplicate.errors[:stripe_subscription_id].any?
  end

  # — Methods —
  test "days_until_trial_ends retourne le nombre de jours restants" do
    sub = build(:subscription, :trialing, trial_ends_at: 7.days.from_now)
    assert_equal 7, sub.days_until_trial_ends
  end

  test "days_until_trial_ends retourne 0 si trial_ends_at est nil" do
    sub = build(:subscription, trial_ends_at: nil)
    assert_equal 0, sub.days_until_trial_ends
  end

  test "suspend! passe la souscription en suspended et la company en suspended" do
    company = create(:company, status: :active)
    sub     = create(:subscription, company: company, status: :active)
    sub.suspend!
    assert sub.reload.suspended?
    assert company.reload.suspended?
  end

  test "reactivate! passe la souscription en active et la company en active" do
    company = create(:company, status: :suspended)
    sub     = create(:subscription, :suspended, company: company)
    sub.reactivate!
    assert sub.reload.active?
    assert company.reload.active?
  end
end
