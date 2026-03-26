class CreateEmployeeAbsences < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_absences do |t|
      t.references :employee, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at,   null: false
      t.string   :reason,    null: false, default: "other"
      t.text     :note

      t.timestamps
    end

    add_index :employee_absences, [ :employee_id, :starts_at, :ends_at ],
              name: "index_employee_absences_on_employee_and_range"
  end
end
