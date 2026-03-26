require "test_helper"

class ReviewRequestJobTest < ActiveSupport::TestCase
  setup do
    @company      = create(:company)
    @service_type = create(:service_type, company: @company)
    @client       = create(:user, role: :client)
    @appointment  = create(:appointment, :completed,
      company:      @company,
      service_type: @service_type,
      client_user:  @client)
  end

  test "crée un Review et envoie un email" do
    assert_difference -> { Review.count }, +1 do
      assert_difference -> { ActionMailer::Base.deliveries.count }, +1 do
        ReviewRequestJob.new.perform(@appointment.id)
      end
    end
  end

  test "ne crée pas de doublon si review déjà existant" do
    create(:review, :pending,
      appointment: @appointment, company: @company, client_user: @client)
    assert_no_difference -> { Review.count } do
      ReviewRequestJob.new.perform(@appointment.id)
    end
  end

  test "ne fait rien si l'appointment n'existe pas" do
    assert_no_difference -> { Review.count } do
      ReviewRequestJob.new.perform(999_999)
    end
  end

  test "ne fait rien si l'appointment n'est pas completed" do
    @appointment.update!(status: :confirmed)
    assert_no_difference -> { Review.count } do
      ReviewRequestJob.new.perform(@appointment.id)
    end
  end

  test "ne fait rien si pas de client_user" do
    appointment_no_client = create(:appointment, :completed,
      company:      @company,
      service_type: @service_type,
      client_user:  nil)
    assert_no_difference -> { Review.count } do
      ReviewRequestJob.new.perform(appointment_no_client.id)
    end
  end
end
