class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :company,    null: false, foreign_key: true
      t.references :notifiable, null: true,  polymorphic: true
      t.integer    :kind,       null: false, default: 0
      t.datetime   :read_at

      t.timestamps
    end

    add_index :notifications, [ :company_id, :read_at ]
    add_index :notifications, [ :company_id, :created_at ]
  end
end
