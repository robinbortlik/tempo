class CreateDataAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :data_audit_logs do |t|
      # What was changed
      t.string :auditable_type, null: false   # e.g., "MoneyTransaction"
      t.integer :auditable_id, null: false    # ID of the changed record

      # What happened
      t.string :action, null: false           # "create", "update", "destroy"
      t.json :changes_made                     # Hash of attribute changes (old -> new)

      # Who/what made the change
      t.string :source                         # Plugin name or "user"
      t.integer :sync_history_id               # Link to specific sync operation (optional)

      t.timestamps
    end

    add_index :data_audit_logs, [:auditable_type, :auditable_id]
    add_index :data_audit_logs, :source
    add_index :data_audit_logs, :sync_history_id
    add_index :data_audit_logs, :action
    add_index :data_audit_logs, :created_at
  end
end
