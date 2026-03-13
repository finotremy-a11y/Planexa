class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :appointment,  null: false, foreign_key: true, index: { unique: true }
      t.references :client_user,  null: false, foreign_key: { to_table: :users }
      t.references :company,      null: false, foreign_key: true

      t.string  :stripe_payment_intent_id, null: false
      t.string  :stripe_transfer_id
      t.integer :amount_cents,             null: false
      t.string  :currency,                 null: false, default: "eur"
      t.integer :status,                   null: false, default: 0
      # enum: pending, succeeded, failed, refunded

      t.datetime :paid_at

      t.timestamps
    end

    add_index :payments, :stripe_payment_intent_id, unique: true
    add_index :payments, :status
  end
end
