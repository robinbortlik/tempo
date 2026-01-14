class AddPaidAtToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :paid_at, :datetime
  end
end
