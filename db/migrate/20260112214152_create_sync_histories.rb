class CreateSyncHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_histories do |t|
      t.string :plugin_name, null: false
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :records_processed, default: 0
      t.integer :records_created, default: 0
      t.integer :records_updated, default: 0
      t.text :error_message
      t.text :error_backtrace
      t.text :metadata

      t.timestamps
    end

    add_index :sync_histories, :plugin_name
    add_index :sync_histories, :status
  end
end
