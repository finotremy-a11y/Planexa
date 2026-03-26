class AddReminderChannelsToCompanySettings < ActiveRecord::Migration[8.0]
  def change
    add_column :company_settings, :email_reminders_enabled, :boolean, default: true, null: false
    add_column :company_settings, :push_reminders_enabled, :boolean, default: false, null: false
  end
end
