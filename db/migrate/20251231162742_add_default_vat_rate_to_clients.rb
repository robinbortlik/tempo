class AddDefaultVatRateToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :default_vat_rate, :decimal, precision: 5, scale: 2
  end
end
