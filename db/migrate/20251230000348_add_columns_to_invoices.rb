class AddColumnsToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_reference :invoices, :client, null: false, foreign_key: true
    add_column :invoices, :number, :string, null: false
    add_column :invoices, :status, :integer, default: 0, null: false
    add_column :invoices, :issue_date, :date
    add_column :invoices, :due_date, :date
    add_column :invoices, :period_start, :date
    add_column :invoices, :period_end, :date
    add_column :invoices, :total_hours, :decimal, precision: 8, scale: 2
    add_column :invoices, :total_amount, :decimal, precision: 12, scale: 2
    add_column :invoices, :currency, :string
    add_column :invoices, :notes, :text

    add_index :invoices, :number, unique: true
    add_index :invoices, :status
  end
end
