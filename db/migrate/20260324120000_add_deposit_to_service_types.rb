class AddDepositToServiceTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :service_types, :deposit_kind, :integer, default: 0, null: false
    add_column :service_types, :deposit_value, :integer, default: 0, null: false

    add_index :service_types, :deposit_kind
  end
end
