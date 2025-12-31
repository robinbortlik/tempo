class Invoice < ApplicationRecord
  # Associations
  belongs_to :client
  has_many :work_entries, dependent: :nullify
  has_many :line_items, class_name: "InvoiceLineItem", dependent: :destroy

  # Alias for backwards compatibility during migration
  alias_method :time_entries, :work_entries

  # Enums
  enum :status, { draft: 0, final: 1 }

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

  # Calculates and updates total_hours and total_amount
  # Uses line_items if present, otherwise falls back to work_entries
  def calculate_totals
    if line_items.any?
      self.total_hours = line_items.time_aggregate.sum(:quantity) || 0
      self.total_amount = line_items.sum(:amount)
    else
      self.total_hours = work_entries.sum(:hours) || 0
      self.total_amount = work_entries.sum { |entry| entry.calculated_amount || 0 }
    end
    self
  end

  # Calculates and saves totals
  def calculate_totals!
    calculate_totals
    save!
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
