class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :client, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
