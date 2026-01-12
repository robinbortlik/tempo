class SyncHistory < ApplicationRecord
  # Enums
  enum :status, { pending: 0, running: 1, completed: 2, failed: 3 }

  # Validations
  validates :plugin_name, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc).limit(10) }
  scope :for_plugin, ->(name) { where(plugin_name: name) }

  # Returns the duration of the sync in seconds
  # Returns nil if started_at or completed_at is missing
  def duration
    return nil unless started_at && completed_at

    completed_at - started_at
  end
end
