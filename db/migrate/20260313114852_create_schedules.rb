class CreateSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :company,  null: false, foreign_key: true

      # Pour les créneaux récurrents (hebdo)
      t.integer :day_of_week   # 0=Dimanche, 1=Lundi ... 6=Samedi
      t.time    :start_time
      t.time    :end_time

      # Pour les exceptions (congés, jours fériés, créneaux ponctuels)
      t.date    :specific_date
      t.boolean :available, default: true

      t.string  :schedule_type, default: "recurring"  # recurring / exception

      t.timestamps
    end

    add_index :schedules, [:employee_id, :day_of_week]
    add_index :schedules, [:employee_id, :specific_date]
  end
end
