class AddSharingEnabledToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :sharing_enabled, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        # Set sharing_enabled to true for all existing clients (backwards compatibility)
        execute <<-SQL
          UPDATE clients SET sharing_enabled = true
        SQL
      end
    end
  end
end
