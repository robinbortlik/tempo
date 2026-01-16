class ExchangeRate < ApplicationRecord
  # Validations
  validates :base_currency, presence: true,
                            format: { with: /\A[A-Z]{3}\z/, message: "must be 3 uppercase letters (e.g., CZK, EUR, USD)" }
  validates :quote_currency, presence: true,
                             format: { with: /\A[A-Z]{3}\z/, message: "must be 3 uppercase letters (e.g., EUR, USD, GBP)" }
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :date, presence: true
  validates :quote_currency, uniqueness: { scope: [ :base_currency, :date ] }
end
