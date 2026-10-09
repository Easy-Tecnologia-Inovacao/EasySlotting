class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.bigint :user_id
      t.bigint :establishment_id
      t.string :action, null: false
      t.string :auditable_type
      t.bigint :auditable_id
      t.string :ip_address
      t.jsonb :details, default: {}

      t.timestamps
    end

    add_index :audit_logs, :user_id
    add_index :audit_logs, :establishment_id
    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :created_at
  end
end
