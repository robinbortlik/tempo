class CreateBankAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_accounts do |t|
      t.string :name, null: false
      t.string :bank_name
      t.string :bank_account
      t.string :bank_swift
      t.string :iban, null: false
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :bank_accounts, :is_default
  end
end
