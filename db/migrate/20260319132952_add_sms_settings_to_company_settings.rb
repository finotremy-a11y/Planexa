class AddSmsSettingsToCompanySettings < ActiveRecord::Migration[8.0]
  def change
    add_column :company_settings, :sms_reminders_enabled, :boolean, default: false, null: false
  end
end
