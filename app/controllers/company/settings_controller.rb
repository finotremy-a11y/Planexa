class Company::SettingsController < Company::BaseController
  def show
    @setting = @company.setting
    @recent_reminder_deliveries = @company.reminder_deliveries
                                        .includes(:appointment)
                                        .recent
                                        .limit(12)
  end

  def update
    @setting = @company.setting
    if @setting.update(setting_params)
      sensitive_fields = %w[
        slot_interval_minutes
        buffer_between_appointments_minutes
        allow_controlled_overbooking
        overbooking_limit_per_slot
        emergency_daily_capacity
      ]
      changed_sensitive_fields = @setting.saved_changes.keys & sensitive_fields
      if changed_sensitive_fields.any?
        MedicalAuditLogger.log!(
          company: @company,
          user: current_user,
          action: "medical_settings_updated",
          record: @setting,
          metadata: { changed_fields: changed_sensitive_fields }
        )
      end

      redirect_to company_settings_path,
        notice: "Réglages sauvegardés."
    else
      @recent_reminder_deliveries = @company.reminder_deliveries
                                          .includes(:appointment)
                                          .recent
                                          .limit(12)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:company_setting).permit(
      :booking_mode,
      :payment_mode,
      :assignment_mode,
      :email_reminders_enabled,
      :sms_reminders_enabled,
      :push_reminders_enabled,
      :slot_interval_minutes,
      :buffer_between_appointments_minutes,
      :allow_controlled_overbooking,
      :overbooking_limit_per_slot,
      :emergency_daily_capacity
    )
  end
end
