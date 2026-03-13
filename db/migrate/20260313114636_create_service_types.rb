class CreateServiceTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :service_types do |t|
      t.references :company, null: false, foreign_key: true

      t.string  :name,             null: false
      t.text    :description
      t.integer :duration_minutes, null: false, default: 60
      t.integer :price_cents,      null: false, default: 0
      t.string  :price_currency,   null: false, default: "EUR"
      t.boolean :active,           default: true

      t.timestamps
    end

    add_index :service_types, [:company_id, :name]
    add_index :service_types, :active
  end
end
