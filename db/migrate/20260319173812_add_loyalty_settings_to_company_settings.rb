class AddLoyaltySettingsToCompanySettings < ActiveRecord::Migration[8.0]
  def change
    add_column :company_settings, :loyalty_enabled,          :boolean, default: false, null: false
    add_column :company_settings, :points_per_appointment,   :integer, default: 10, null: false
    add_column :company_settings, :loyalty_points_threshold,  :integer, default: 100, null: false
    add_column :company_settings, :loyalty_discount_value_cents, :integer, default: 1000, null: false
  end
end
