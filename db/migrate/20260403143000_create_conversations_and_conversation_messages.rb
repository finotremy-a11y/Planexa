# frozen_string_literal: true

class CreateConversationsAndConversationMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client_user, null: false, foreign_key: { to_table: :users }
      t.datetime :client_last_read_at
      t.datetime :company_last_read_at

      t.timestamps
    end

    add_index :conversations, [ :company_id, :client_user_id ], unique: true

    create_table :conversation_messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body

      t.timestamps
    end

    add_index :conversation_messages, [ :conversation_id, :created_at ]
  end
end
