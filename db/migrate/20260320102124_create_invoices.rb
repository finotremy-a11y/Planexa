class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :payment, null: false, foreign_key: true, index: { unique: true }
      t.references :company, null: false, foreign_key: true
      t.references :client_user, null: true, foreign_key: { to_table: :users }

      t.string  :invoice_number, null: false
      t.integer :subtotal_cents, null: false, default: 0
      t.decimal :tax_rate,       null: false, default: 0.20, precision: 5, scale: 4
      t.integer :tax_amount_cents, null: false, default: 0
      t.integer :total_cents,    null: false, default: 0
      t.string  :currency,       null: false, default: "EUR"
      t.datetime :issued_at,     null: false

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, %i[company_id issued_at]
  end
end
