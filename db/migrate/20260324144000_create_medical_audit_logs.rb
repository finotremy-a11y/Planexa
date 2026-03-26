class CreateMedicalAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :medical_audit_logs do |t|
      t.references :company, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :medical_audit_logs, [ :company_id, :created_at ]
    add_index :medical_audit_logs, [ :record_type, :record_id ]
    add_index :medical_audit_logs, :action
  end
end
