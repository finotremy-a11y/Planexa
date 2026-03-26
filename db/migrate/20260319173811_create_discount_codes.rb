class CreateDiscountCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :discount_codes do |t|
      t.references :company,     null: false, foreign_key: true
      t.references :client_user, null: false, foreign_key: { to_table: :users }
      t.string  :code,           null: false
      t.integer :discount_type,  null: false, default: 0
      t.integer :discount_value_cents, null: false, default: 0
      t.datetime :used_at
      t.datetime :expires_at,    null: false

      t.timestamps
    end

    add_index :discount_codes, :code, unique: true
    add_index :discount_codes, [ :client_user_id, :company_id ]
  end
end
