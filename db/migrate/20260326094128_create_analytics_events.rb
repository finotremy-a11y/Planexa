class CreateAnalyticsEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :analytics_events do |t|
      t.string  :name,       null: false
      t.bigint  :company_id
      t.bigint  :user_id
      t.string  :session_id
      t.jsonb   :properties, null: false, default: {}
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :analytics_events, :name
    add_index :analytics_events, :company_id
    add_index :analytics_events, :created_at
    add_index :analytics_events, [:name, :company_id]
  end
end
