class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates do |t|
      t.string :currency, null: false
      t.decimal :rate, precision: 12, scale: 6, null: false
      t.integer :amount, null: false
      t.date :date, null: false

      t.timestamps
    end

    add_index :exchange_rates, [:currency, :date], unique: true
  end
end
