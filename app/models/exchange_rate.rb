class ExchangeRate < ApplicationRecord
  # Validations
  validates :currency, presence: true,
                       format: { with: /\A[A-Z]{3}\z/, message: "must be 3 uppercase letters (e.g., EUR, USD, GBP)" }
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :date, presence: true
  validates :currency, uniqueness: { scope: :date }
end
