class AddSmsOptOutToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sms_opt_out, :boolean, default: false, null: false
  end
end
