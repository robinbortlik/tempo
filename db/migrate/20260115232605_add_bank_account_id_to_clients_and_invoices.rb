class AddBankAccountIdToClientsAndInvoices < ActiveRecord::Migration[8.1]
  def change
    add_reference :clients, :bank_account, null: true, foreign_key: true
    add_reference :invoices, :bank_account, null: true, foreign_key: true
  end
end
