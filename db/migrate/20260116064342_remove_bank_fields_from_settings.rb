class RemoveBankFieldsFromSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :settings, :bank_name, :string
    remove_column :settings, :bank_account, :string
    remove_column :settings, :bank_swift, :string
    remove_column :settings, :iban, :string
  end
end
