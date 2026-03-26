class AddHealthcareProfileFieldsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :professional_category, :integer, default: 0, null: false
    add_column :companies, :health_specialty, :string
    add_column :companies, :convention_sector, :string
    add_column :companies, :teleconsultation_enabled, :boolean, default: false, null: false

    add_index :companies, :professional_category
  end
end
