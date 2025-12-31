class AddVatRateToInvoiceLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :invoice_line_items, :vat_rate, :decimal, precision: 5, scale: 2, default: 0, null: false
  end
end
