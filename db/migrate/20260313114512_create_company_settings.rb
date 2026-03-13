class CreateCompanySettings < ActiveRecord::Migration[8.0]
  def change
    create_table :company_settings do |t|
      t.references :company, null: false, foreign_key: true, index: { unique: true }

      t.integer :booking_mode,    null: false, default: 0  # public, private
      t.integer :payment_mode,    null: false, default: 1  # in_app, external
      t.integer :assignment_mode, null: false, default: 0  # automatic, manual

      t.timestamps
    end
  end
end
