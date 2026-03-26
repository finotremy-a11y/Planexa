class CreateReminderDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :reminder_deliveries do |t|
      t.references :company, null: false, foreign_key: true
      t.references :appointment, null: false, foreign_key: true
      t.integer :channel, null: false
      t.integer :status, null: false
      t.datetime :delivered_at
      t.text :error_message

      t.timestamps
    end

    add_index :reminder_deliveries, [ :company_id, :created_at ]
    add_index :reminder_deliveries, [ :appointment_id, :channel ]
  end
end
