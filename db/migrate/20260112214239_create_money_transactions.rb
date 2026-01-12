class CreateMoneyTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :money_transactions do |t|
      t.string :external_id
      t.string :source, null: false
      t.integer :transaction_type, null: false, default: 0
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false, default: "EUR"
      t.text :description
      t.date :transacted_on, null: false
      t.string :counterparty
      t.string :reference
      t.references :invoice, foreign_key: true
      t.text :raw_data

      t.timestamps
    end

    add_index :money_transactions, :external_id
    add_index :money_transactions, :source
    add_index :money_transactions, :transacted_on
  end
end
