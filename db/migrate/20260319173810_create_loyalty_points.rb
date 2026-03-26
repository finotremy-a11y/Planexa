class CreateLoyaltyPoints < ActiveRecord::Migration[8.0]
  def change
    create_table :loyalty_points do |t|
      t.references :client_user, null: false, foreign_key: { to_table: :users }
      t.references :company,     null: false, foreign_key: true
      t.references :appointment, foreign_key: true
      t.integer :points,         null: false
      t.string  :reason,         null: false, default: "earned"

      t.timestamps
    end

    add_index :loyalty_points, [ :client_user_id, :company_id ]
  end
end
