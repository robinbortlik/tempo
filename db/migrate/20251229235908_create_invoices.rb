# Note: This is a minimal migration to support TimeEntry associations.
# Full fields will be added in task 3.5 Invoice Model migration.
class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.timestamps
    end
  end
end
