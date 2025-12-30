class TimeEntry < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :invoice, optional: true

  # Enums
  enum :status, { unbilled: 0, invoiced: 1 }

  # Validations
  validates :date, presence: true
  validates :hours, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }

  # Calculates the monetary amount based on hours and the project's effective hourly rate
  def calculated_amount
    return nil unless hours && project&.effective_hourly_rate
    hours * project.effective_hourly_rate
  end
end
