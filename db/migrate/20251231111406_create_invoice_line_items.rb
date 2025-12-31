class CreateInvoiceLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.integer :line_type, null: false, default: 0  # time_aggregate=0, fixed=1
      t.text :description, null: false
      t.decimal :quantity, precision: 8, scale: 2     # Hours for time entries, null for fixed
      t.decimal :unit_price, precision: 10, scale: 2  # Rate for time entries, null for fixed
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end
