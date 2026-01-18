class AddMainCurrencyToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :main_currency, :string, default: "CZK"
  end
end
