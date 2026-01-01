class AddIbanAndInvoiceMessageToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :iban, :string
    add_column :settings, :invoice_message, :text
  end
end
