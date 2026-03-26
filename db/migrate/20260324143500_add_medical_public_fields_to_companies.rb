class AddMedicalPublicFieldsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :accessibility_info, :text
    add_column :companies, :practical_info, :text
    add_column :companies, :cancellation_policy, :text
  end
end
