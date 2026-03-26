class CreateCompanyClosures < ActiveRecord::Migration[8.0]
  def change
    create_table :company_closures do |t|
      t.references :company, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :reason
      t.text :note

      t.timestamps
    end

    add_index :company_closures, [ :company_id, :starts_at, :ends_at ], name: "index_company_closures_on_company_and_range"
  end
end
