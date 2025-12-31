class Project < ApplicationRecord
  # Associations
  belongs_to :client
  has_many :work_entries, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :hourly_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Returns the project's hourly_rate if set, otherwise falls back to the client's hourly_rate
  def effective_hourly_rate
    hourly_rate || client&.hourly_rate
  end
end
