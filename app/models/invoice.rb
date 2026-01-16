class Invoice < ApplicationRecord
  # Associations
  belongs_to :client
  belongs_to :bank_account, optional: true
  has_many :work_entries, dependent: :nullify
  has_many :line_items, class_name: "InvoiceLineItem", dependent: :destroy

  # Alias for backwards compatibility during migration
  alias_method :time_entries, :work_entries

  # Enums
  enum :status, { draft: 0, final: 1, paid: 2 }

  # Callbacks
  before_validation :set_invoice_number, on: :create

  # Validations
  validates :number, presence: true, uniqueness: true
  validates :client, presence: true
  validates :currency, format: { with: /\A[A-Z]{3}\z/, message: "must be 3 uppercase letters (e.g., EUR, USD, GBP)" },
                       allow_blank: true
  validates :total_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :period_end_after_period_start
  validate :due_date_after_issue_date

  # Scopes
  scope :for_year, ->(year) { where("number LIKE ?", "#{year}-%") }
  scope :for_client, ->(client) { where(client: client) }
  scope :payable, -> { final }

  # Calculates and updates total_hours and total_amount
  # Uses line_items if present, otherwise falls back to work_entries
  def calculate_totals
    if line_items.any?
      self.total_hours = line_items.time_aggregate.sum(:quantity) || 0
      self.total_amount = grand_total
    else
      self.total_hours = work_entries.sum(:hours) || 0
      self.total_amount = work_entries.sum { |entry| entry.calculated_amount || 0 }
    end
    self
  end

  # Sum of all line item amounts (before VAT)
  def subtotal
    line_items.sum(:amount)
  end

  # Sum of all line item VAT amounts
  def total_vat
    line_items.sum(&:vat_amount)
  end

  # Subtotal plus total VAT
  def grand_total
    subtotal + total_vat
  end

  # Groups VAT amounts by rate, returning a hash like { 21.0 => 105.00, 0.0 => 0.00 }
  def vat_totals_by_rate
    line_items.group_by(&:vat_rate).transform_values do |items|
      items.sum(&:vat_amount)
    end
  end

  # Calculates and saves totals
  def calculate_totals!
    calculate_totals
    save!
  end

  # Marks the invoice as paid with the given date (defaults to today)
  def mark_as_paid!(date = nil)
    update!(status: :paid, paid_at: date || Date.current)
  end

  # Converts grand_total to main currency using exchange rate from issue_date
  # Returns nil if no exchange rate available or currency is nil
  # Returns original amount if invoice currency matches main currency
  def main_currency_amount
    return nil if currency.blank?

    main_currency = Setting.instance.main_currency
    return grand_total.to_f if currency == main_currency

    exchange_rate = ExchangeRate.find_by(currency: currency, date: issue_date)
    return nil if exchange_rate.nil?

    (grand_total * (exchange_rate.rate / exchange_rate.amount)).to_f
  end

  private

  def set_invoice_number
    self.number ||= InvoiceNumberGenerator.generate
  end

  def period_end_after_period_start
    return unless period_start.present? && period_end.present?

    if period_end < period_start
      errors.add(:period_end, "must be after or equal to period start")
    end
  end

  def due_date_after_issue_date
    return unless issue_date.present? && due_date.present?

    if due_date < issue_date
      errors.add(:due_date, "must be after or equal to issue date")
    end
  end
end
