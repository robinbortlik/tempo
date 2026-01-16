class RefactorExchangeRatesForGenericCurrencies < ActiveRecord::Migration[8.1]
  def change
    # Remove existing records (they only had implicit base currency)
    ExchangeRate.delete_all

    # Remove old index
    remove_index :exchange_rates, [ :currency, :date ]

    # Rename currency to quote_currency for clarity
    rename_column :exchange_rates, :currency, :quote_currency

    # Add base_currency column (the currency we're converting TO)
    add_column :exchange_rates, :base_currency, :string, null: false

    # Add new unique index on all three columns
    add_index :exchange_rates, [ :base_currency, :quote_currency, :date ], unique: true
  end
end
