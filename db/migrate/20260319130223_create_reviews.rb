class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :appointment,  null: false, foreign_key: true
      t.references :client_user,  null: false, foreign_key: { to_table: :users }
      t.references :company,      null: false, foreign_key: true
      t.integer    :rating        # null until client submits
      t.text       :comment
      t.string     :token,        null: false
      t.datetime   :submitted_at
      t.datetime   :published_at
      t.datetime   :expires_at,   null: false

      t.timestamps
    end

    add_index :reviews, :token,          unique: true
    add_index :reviews, :published_at

    # Ensure appointment_id is UNIQUE (1 review per appointment)
    # t.references already creates a basic index; we add the unique constraint
    add_index :reviews, :appointment_id, unique: true, name: "index_reviews_on_appointment_id_unique"
  end
end
