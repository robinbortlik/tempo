class WorkEntry < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :invoice, optional: true
  has_many :invoice_line_item_work_entries, dependent: :destroy
  has_many :invoice_line_items, through: :invoice_line_item_work_entries

  # Enums
  enum :entry_type, { time: 0, fixed: 1 }
  enum :status, { unbilled: 0, invoiced: 1 }

  # Validations
  validates :date, presence: true
  validates :hours, numericality: { greater_than: 0 }, allow_nil: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :at_least_hours_or_amount_present
  validate :hourly_rate_locked_when_invoiced

  # Callbacks
  before_validation :detect_entry_type
  before_validation :populate_hourly_rate

  # Scopes
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :by_entry_type, ->(type) { where(entry_type: type) }

  # Calculates the monetary amount based on hours and the project's effective hourly rate
  # Returns custom amount if set, otherwise calculates from hours * rate
  def calculated_amount
    return amount if amount.present?
    return nil unless hours

    rate = hourly_rate || project&.effective_hourly_rate
    return nil unless rate

    hours * rate
  end

  private

  # Auto-detect entry_type based on input fields
  # - hours only = time
  # - amount only = fixed
  # - both hours AND amount = time (with custom pricing override)
  def detect_entry_type
    if hours.present? && amount.blank?
      self.entry_type = :time
    elsif amount.present? && hours.blank?
      self.entry_type = :fixed
    elsif hours.present? && amount.present?
      self.entry_type = :time
    end
    # If neither is set, leave entry_type as default (time)
  end

  # Auto-populate hourly_rate from project for time-based entries
  # Only populates if not already set (allows user override)
  def populate_hourly_rate
    return unless time?
    return if hourly_rate.present?

    self.hourly_rate = project&.effective_hourly_rate
  end

  # Prevent changes to hourly_rate on invoiced entries
  def hourly_rate_locked_when_invoiced
    return unless hourly_rate_changed? && invoiced?

    errors.add(:hourly_rate, "cannot be changed on invoiced entries")
  end

  def at_least_hours_or_amount_present
    if hours.blank? && amount.blank?
      errors.add(:base, "Either hours or amount must be provided")
    end
  end
end
