class AddReconfirmationToAppointments < ActiveRecord::Migration[8.0]
  def change
    add_column :appointments, :reconfirmation_requested_at, :datetime
    add_column :appointments, :reconfirmed_at, :datetime

    add_index :appointments, :reconfirmation_requested_at
    add_index :appointments, :reconfirmed_at
  end
end
