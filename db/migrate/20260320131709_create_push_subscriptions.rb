class CreatePushSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :auth, null: false
      t.string :p256dh, null: false

      t.timestamps
    end

    # Unique index: une souscription par utilisateur+compagnie
    add_index :push_subscriptions, [:user_id, :company_id, :endpoint], unique: true, name: 'idx_push_sub_unique'
  end
end
