class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :company, null: false, foreign_key: true, index: { unique: true }

      t.string   :stripe_subscription_id, null: false
      t.string   :stripe_price_id,        null: false
      t.integer  :status,                 null: false, default: 0
      # enum: trialing, active, past_due, canceled, suspended

      t.datetime :trial_ends_at
      t.datetime :current_period_end
      t.datetime :suspended_at

      t.timestamps
    end

    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, :status
  end
end
