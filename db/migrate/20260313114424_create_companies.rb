class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.references :user, null: false, foreign_key: true

      t.string :name,        null: false
      t.string :siret,       null: false
      t.string :address,     null: false
      t.string :city,        null: false
      t.string :zip_code,    null: false
      t.string :phone
      t.text   :description
      t.string :website
      t.string :logo_public_id   # Cloudinary public_id

      # Stripe
      t.string :stripe_account_id   # Stripe Connect Express (pour recevoir paiements clients)
      t.string :stripe_customer_id  # Pour son propre abonnement à la plateforme
      t.boolean :stripe_onboarding_complete, default: false

      # Statut
      t.integer :status, default: 0, null: false  # enum: active, suspended, pending

      t.timestamps
    end

    add_index :companies, :siret, unique: true
    add_index :companies, :status
    add_index :companies, :name
  end
end
