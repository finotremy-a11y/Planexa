class CreateApiWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :api_webhooks do |t|
      t.references :company, null: false, foreign_key: true
      t.string :url, null: false
      t.jsonb :events, null: false, default: []
      t.string :secret, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :api_webhooks, :active
  end
end
