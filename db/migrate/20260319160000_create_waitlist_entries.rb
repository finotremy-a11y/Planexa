class CreateWaitlistEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :waitlist_entries do |t|
      t.references :company,      null: false, foreign_key: true
      t.references :service_type, null: false, foreign_key: true
      t.references :client_user,  foreign_key: { to_table: :users }
      t.string     :client_email
      t.string     :client_name
      t.date       :preferred_date
      t.string     :token,        null: false
      t.datetime   :notified_at
      t.datetime   :expired_at
      t.timestamps
    end

    add_index :waitlist_entries, :token, unique: true
    add_index :waitlist_entries, [:company_id, :service_type_id, :created_at],
              name: "index_waitlist_on_company_service_created"
    add_index :waitlist_entries, :notified_at
    add_index :waitlist_entries, :expired_at
  end
end
