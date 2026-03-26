# frozen_string_literal: true

class CreateBookingGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_groups do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client_user, foreign_key: { to_table: :users }
      t.integer :total_amount_cents, default: 0, null: false
      t.string :currency, default: "EUR", null: false
      t.integer :status, default: 0, null: false
      t.text :client_notes
      t.timestamps
    end

    add_reference :appointments, :booking_group, foreign_key: true, null: true
  end
end
