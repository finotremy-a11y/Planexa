class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.references :company, null: false, foreign_key: true

      t.string :first_name, null: false
      t.string :last_name,  null: false
      t.string :email
      t.string :phone
      t.string :photo_public_id   # Cloudinary
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :employees, [:company_id, :active]
  end
end
