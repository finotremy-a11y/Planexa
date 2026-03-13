class CreateEmployeeSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_skills do |t|
      t.references :employee,     null: false, foreign_key: true
      t.references :service_type, null: false, foreign_key: true

      t.integer :level, default: 1  # enum: beginner, intermediate, expert

      t.timestamps
    end

    add_index :employee_skills, [:employee_id, :service_type_id], unique: true
  end
end
