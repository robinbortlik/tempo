class InvoiceLineItem < ApplicationRecord
  # Associations
  belongs_to :invoice
  has_many :invoice_line_item_work_entries, dependent: :destroy
  has_many :work_entries, through: :invoice_line_item_work_entries

  # Enums
  enum :line_type, { time_aggregate: 0, fixed: 1 }

  # Validations
  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :vat_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Default scope - order by position
  default_scope { order(:position) }

  # Calculates the VAT amount for this line item
  def vat_amount
    (amount * (vat_rate / 100)).round(2)
  end
end
