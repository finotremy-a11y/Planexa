class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.references :company,      null: false, foreign_key: true
      t.references :service_type, null: false, foreign_key: true
      t.references :client_user,  null: true,  foreign_key: { to_table: :users }
      t.references :employee,     null: true,  foreign_key: true

      t.datetime :scheduled_at,      null: false
      t.integer  :duration_minutes,  null: false
      t.integer  :status,            null: false, default: 0
      # enum: pending, confirmed, cancelled, completed, no_show

      t.integer  :booking_source, default: 0   # online, manual (saisi par l'entreprise)
      t.boolean  :urgent,         default: false

      t.text :client_notes      # Notes du client lors de la réservation
      t.text :internal_notes    # Notes internes à l'entreprise

      t.string :cancellation_reason

      t.timestamps
    end

    add_index :appointments, [:company_id, :scheduled_at]
    add_index :appointments, [:employee_id, :scheduled_at]
    add_index :appointments, [:client_user_id, :scheduled_at]
    add_index :appointments, :status
    add_index :appointments, :urgent
  end
end
