class MoneyTransaction < ApplicationRecord
  # Associations
  belongs_to :invoice, optional: true

  # Enums
  enum :transaction_type, { income: 0, expense: 1 }

  # Validations
  validates :source, :amount, :currency, :transacted_on, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :external_id, uniqueness: { scope: :source }, allow_nil: true

  # Scopes
  scope :income, -> { where(transaction_type: :income) }
  scope :expenses, -> { where(transaction_type: :expense) }
  scope :unmatched, -> { where(invoice_id: nil) }
  scope :for_period, ->(start_date, end_date) { where(transacted_on: start_date..end_date) }
end
