class CreatePluginConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :plugin_configurations do |t|
      t.string :plugin_name, null: false
      t.boolean :enabled, default: false, null: false
      t.text :credentials
      t.text :settings

      t.timestamps
    end

    add_index :plugin_configurations, :plugin_name, unique: true
  end
end
