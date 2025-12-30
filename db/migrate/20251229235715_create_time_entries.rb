class CreateTimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :time_entries do |t|
      t.references :project, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :hours, precision: 6, scale: 2, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.integer :invoice_id, null: true

      t.timestamps
    end

    add_index :time_entries, :date
    add_index :time_entries, :status
    add_index :time_entries, [:project_id, :date]
    add_index :time_entries, :invoice_id
  end
end
