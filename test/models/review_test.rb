require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    @company      = create(:company)
    @service_type = create(:service_type, company: @company)
    @client       = create(:user, role: :client)
    @appointment  = create(:appointment, :completed,
      company:      @company,
      service_type: @service_type,
      client_user:  @client)
  end

  # ── Validations ────────────────────────────────────────────────────────────

  test "valide avec des attributs corrects" do
    review = build(:review, :pending,
      appointment: @appointment,
      company:     @company,
      client_user: @client)
    assert review.valid?, review.errors.full_messages.inspect
  end

  test "invalide sans token" do
    review = create(:review, :pending,
      appointment: @appointment,
      company:     @company,
      client_user: @client)
    review.token = nil
    assert_not review.valid?
    assert review.errors[:token].any?
  end

  test "invalide sans expires_at" do
    review = create(:review, :pending,
      appointment: @appointment,
      company:     @company,
      client_user: @client)
    review.expires_at = nil
    assert_not review.valid?
    assert review.errors[:expires_at].any?
  end

  test "invalide si rating hors de 1-5 lors de la soumission" do
    review = build(:review, :pending,
      appointment:  @appointment,
      company:      @company,
      client_user:  @client,
      rating:       6,
      submitted_at: Time.current)
    assert_not review.valid?
    assert review.errors[:rating].any?
  end

  test "invalide si rating nul lors de la soumission" do
    review = build(:review, :pending,
      appointment:  @appointment,
      company:      @company,
      client_user:  @client,
      submitted_at: Time.current)
    assert_not review.valid?
    assert review.errors[:rating].any?
  end

  test "token auto-généré avant création" do
    review = create(:review, :pending,
      appointment: @appointment,
      company:     @company,
      client_user: @client)
    assert review.token.present?
  end

  test "expires_at auto-défini avant création" do
    review = create(:review, :pending,
      appointment: @appointment,
      company:     @company,
      client_user: @client)
    assert review.expires_at.present?
    assert review.expires_at > Time.current
  end

  # ── Méthodes ───────────────────────────────────────────────────────────────

  test "submitted? retourne true si submitted_at présent" do
    review = build(:review, :submitted,
      appointment: @appointment, company: @company, client_user: @client)
    assert review.submitted?
  end

  test "submitted? retourne false si submitted_at absent" do
    review = build(:review, :pending,
      appointment: @appointment, company: @company, client_user: @client)
    assert_not review.submitted?
  end

  test "expired? retourne true si expires_at passé et non soumis" do
    review = build(:review, :pending, :expired,
      appointment: @appointment, company: @company, client_user: @client)
    assert review.expired?
  end

  test "expired? retourne false si soumis même après expiry" do
    review = build(:review, :submitted, :expired,
      appointment: @appointment, company: @company, client_user: @client)
    assert_not review.expired?
  end

  test "submit! enregistre rating, submitted_at et published_at" do
    review = create(:review, :pending,
      appointment: @appointment, company: @company, client_user: @client)
    review.submit!(rating: 5, comment: "Excellent !")
    assert_equal 5, review.rating
    assert_equal "Excellent !", review.comment
    assert review.submitted_at.present?
    assert review.published_at.present?
  end

  test "unpublish! retire published_at" do
    review = create(:review, :submitted,
      appointment: @appointment, company: @company, client_user: @client)
    review.unpublish!
    assert_nil review.published_at
  end

  test "publish! remet published_at" do
    review = create(:review, :unpublished,
      appointment: @appointment, company: @company, client_user: @client)
    review.publish!
    assert review.published_at.present?
  end

  # ── Scopes ─────────────────────────────────────────────────────────────────

  test "scope published ne retourne que les avis publiés" do
    published = create(:review, :submitted,
      appointment: @appointment, company: @company, client_user: @client)
    unpublished_review = create(:review, :unpublished,
      appointment: create(:appointment, :completed,
        company: @company, service_type: @service_type, client_user: create(:user)),
      company:     @company,
      client_user: create(:user))
    assert_includes Review.published, published
    assert_not_includes Review.published, unpublished_review
  end

  # ── Méthodes de classe ─────────────────────────────────────────────────────

  test "average_rating_for retourne la moyenne des avis publiés" do
    appt2 = create(:appointment, :completed,
      company: @company, service_type: @service_type,
      client_user: create(:user))
    create(:review, :submitted, rating: 4,
      appointment: @appointment, company: @company, client_user: @client)
    create(:review, :submitted, rating: 2,
      appointment: appt2, company: @company, client_user: appt2.client_user)
    avg = Review.average_rating_for(@company)
    assert_equal 3.0, avg
  end
end
