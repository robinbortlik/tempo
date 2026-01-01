class CreateInvoiceLineItemWorkEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_line_item_work_entries do |t|
      t.references :invoice_line_item, null: false, foreign_key: true
      t.references :work_entry, null: false, foreign_key: true

      t.timestamps
    end

    # Add unique index to prevent duplicate links
    add_index :invoice_line_item_work_entries,
              [ :invoice_line_item_id, :work_entry_id ],
              unique: true,
              name: "index_line_item_work_entries_uniqueness"
  end
end
