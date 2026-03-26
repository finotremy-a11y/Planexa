class AddMedicalSchedulingToCompanySettings < ActiveRecord::Migration[8.0]
  def change
    add_column :company_settings, :slot_interval_minutes, :integer, default: 15, null: false
    add_column :company_settings, :buffer_between_appointments_minutes, :integer, default: 0, null: false
    add_column :company_settings, :allow_controlled_overbooking, :boolean, default: false, null: false
    add_column :company_settings, :overbooking_limit_per_slot, :integer, default: 0, null: false
    add_column :company_settings, :emergency_daily_capacity, :integer, default: 0, null: false
  end
end
