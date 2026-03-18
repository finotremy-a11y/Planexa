require "test_helper"

class AppointmentReminderJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  setup do
    @company     = create(:company)
    @service     = create(:service_type, company: @company)
    @client      = create(:user, role: :client)
    @appointment = create(:appointment,
      company:      @company,
      service_type: @service,
      client_user:  @client,
      status:       :confirmed,
      scheduled_at: 2.days.from_now)
  end

  test "envoie un email de rappel pour un RDV confirmé" do
    assert_emails 1 do
      AppointmentReminderJob.new.perform(@appointment.id)
    end
  end

  test "ne fait rien si le RDV est annulé" do
    @appointment.update!(status: :cancelled)
    assert_emails 0 do
      AppointmentReminderJob.new.perform(@appointment.id)
    end
  end

  test "ne fait rien si le RDV est completed" do
    @appointment.update!(status: :completed)
    assert_emails 0 do
      AppointmentReminderJob.new.perform(@appointment.id)
    end
  end

  test "ne fait rien si le RDV est introuvable" do
    assert_emails 0 do
      AppointmentReminderJob.new.perform(999_999)
    end
  end

  test "s'exécute correctement (queue mailers)" do
    assert_equal :mailers, AppointmentReminderJob.new.queue_name.to_sym
  end
end
