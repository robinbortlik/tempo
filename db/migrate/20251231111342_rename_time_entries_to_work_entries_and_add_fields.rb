class RenameTimeEntriesToWorkEntriesAndAddFields < ActiveRecord::Migration[8.1]
  def change
    # Rename table from time_entries to work_entries
    rename_table :time_entries, :work_entries

    # Add entry_type column (time=0/fixed=1, default time, not null)
    add_column :work_entries, :entry_type, :integer, default: 0, null: false

    # Add amount column (nullable decimal 12,2)
    add_column :work_entries, :amount, :decimal, precision: 12, scale: 2

    # Change hours from not null to nullable
    change_column_null :work_entries, :hours, true

    # Add index on entry_type for filtering
    add_index :work_entries, :entry_type

    # Set entry_type = 'time' (0) for all existing records (already default, but be explicit)
    reversible do |dir|
      dir.up do
        execute "UPDATE work_entries SET entry_type = 0"
      end
    end
  end
end
