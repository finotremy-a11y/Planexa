class AddWidgetTokenToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :widget_token, :string
    add_index :companies, :widget_token, unique: true

    # Générer un token pour toutes les entreprises existantes
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE companies SET widget_token = gen_random_uuid()::text WHERE widget_token IS NULL
        SQL
      end
    end

    change_column_null :companies, :widget_token, false
  end
end
