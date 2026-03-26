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

    @company.setting.update!(
      email_reminders_enabled: true,
      sms_reminders_enabled: false,
      push_reminders_enabled: false
    )
  end

  test "envoie un email de rappel pour un RDV confirmé" do
    assert_emails 1 do
      AppointmentReminderJob.new.perform(@appointment.id)
    end

    assert_equal 1, ReminderDelivery.where(appointment: @appointment, channel: :email, status: :sent).count
    assert @appointment.reload.reconfirmation_requested?
  end

  test "n'envoie pas d'email si canal email désactivé" do
    @company.setting.update!(email_reminders_enabled: false)

    assert_emails 0 do
      AppointmentReminderJob.new.perform(@appointment.id)
    end

    assert_equal 1, ReminderDelivery.where(appointment: @appointment, channel: :email, status: :skipped).count
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

  # ── SMS ───────────────────────────────────────────────────────────────────

  test "envoie un SMS quand le client a un téléphone et n'a pas opt-out" do
    @client.update!(phone: "0612345678", sms_opt_out: false)
    @company.setting.update!(sms_reminders_enabled: true)

    SmsService.expects(:send).once.returns(true)
    AppointmentReminderJob.new.perform(@appointment.id)
  end

  test "n'envoie pas de SMS si le client a opt-out" do
    @client.update!(phone: "0612345678", sms_opt_out: true)
    @company.setting.update!(sms_reminders_enabled: true)

    SmsService.expects(:send).never
    AppointmentReminderJob.new.perform(@appointment.id)
  end

  test "n'envoie pas de SMS si le client n'a pas de téléphone" do
    @client.update!(phone: nil, sms_opt_out: false)
    @company.setting.update!(sms_reminders_enabled: true)

    SmsService.expects(:send).never
    AppointmentReminderJob.new.perform(@appointment.id)
  end

  test "n'envoie pas de SMS si les SMS sont désactivés pour l'entreprise" do
    @client.update!(phone: "0612345678", sms_opt_out: false)
    @company.setting.update!(sms_reminders_enabled: false)

    SmsService.expects(:send).never
    AppointmentReminderJob.new.perform(@appointment.id)
  end

  test "envoie une notification push si canal push activé et abonnement présent" do
    @company.setting.update!(push_reminders_enabled: true)
    create(:push_subscription, user: @client, company: @company)

    PushSubscription.any_instance.expects(:send_notification).once
    AppointmentReminderJob.new.perform(@appointment.id)

    assert_equal 1, ReminderDelivery.where(appointment: @appointment, channel: :push, status: :sent).count
  end

  test "skip push si aucun abonnement push" do
    @company.setting.update!(push_reminders_enabled: true)

    AppointmentReminderJob.new.perform(@appointment.id)

    assert_equal 1, ReminderDelivery.where(appointment: @appointment, channel: :push, status: :skipped).count
  end
end
