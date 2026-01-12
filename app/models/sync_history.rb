class SyncHistory < ApplicationRecord
  # Enums
  enum :status, { pending: 0, running: 1, completed: 2, failed: 3 }

  # Validations
  validates :plugin_name, presence: true
  validates :status, presence: true

  # Scopes - Basic
  scope :recent, -> { order(created_at: :desc).limit(10) }
  scope :for_plugin, ->(name) { where(plugin_name: name) }

  # Scopes - By status
  scope :successful, -> { completed }
  scope :unsuccessful, -> { failed }
  scope :in_progress, -> { where(status: [:pending, :running]) }

  # Scopes - Time-based
  scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(created_at: 1.month.ago..Time.current) }

  # Returns the duration of the sync in seconds
  # Returns nil if started_at or completed_at is missing
  def duration
    return nil unless started_at && completed_at

    completed_at - started_at
  end

  # Returns human-readable duration string
  # @return [String, nil] formatted duration (e.g., "1.2s", "45.3s", "2m 15s")
  def duration_formatted
    return nil unless duration

    if duration < 60
      format("%.1fs", duration)
    else
      minutes = (duration / 60).floor
      seconds = (duration % 60).round
      "#{minutes}m #{seconds}s"
    end
  end

  # Returns whether this sync is still in progress
  def in_progress?
    pending? || running?
  end

  # Returns whether this sync completed successfully
  def successful?
    completed?
  end

  # Returns a summary hash for UI display
  # @return [Hash] summary with key metrics
  def summary
    {
      id: id,
      plugin_name: plugin_name,
      status: status,
      started_at: started_at,
      completed_at: completed_at,
      duration: duration,
      duration_formatted: duration_formatted,
      records_processed: records_processed || 0,
      records_created: records_created || 0,
      records_updated: records_updated || 0,
      error_message: error_message,
      successful: successful?
    }
  end

  # Class methods for statistics
  class << self
    # Returns statistics for a specific plugin
    # @param plugin_name [String] the plugin name
    # @return [Hash] statistics hash
    def stats_for_plugin(plugin_name)
      scope = for_plugin(plugin_name)

      {
        plugin_name: plugin_name,
        total_syncs: scope.count,
        successful_syncs: scope.successful.count,
        failed_syncs: scope.unsuccessful.count,
        success_rate: calculate_success_rate(scope),
        last_sync: scope.order(created_at: :desc).first&.summary,
        last_successful_sync: scope.successful.order(created_at: :desc).first&.summary,
        last_failed_sync: scope.unsuccessful.order(created_at: :desc).first&.summary,
        average_duration: calculate_average_duration(scope),
        total_records_processed: scope.successful.sum(:records_processed),
        syncs_today: scope.today.count,
        syncs_this_week: scope.this_week.count
      }
    end

    # Returns aggregate statistics across all plugins
    # @return [Hash] aggregate statistics
    def aggregate_stats
      {
        total_syncs: count,
        successful_syncs: successful.count,
        failed_syncs: unsuccessful.count,
        success_rate: calculate_success_rate(all),
        syncs_today: today.count,
        syncs_this_week: this_week.count,
        plugins_synced: distinct.pluck(:plugin_name).count,
        in_progress: in_progress.count
      }
    end

    private

    def calculate_success_rate(scope)
      total = scope.where(status: [:completed, :failed]).count
      return 0.0 if total.zero?

      ((scope.successful.count.to_f / total) * 100).round(1)
    end

    def calculate_average_duration(scope)
      completed_syncs = scope.successful.where.not(started_at: nil).where.not(completed_at: nil)
      return nil if completed_syncs.empty?

      total_duration = completed_syncs.sum { |s| s.completed_at - s.started_at }
      total_duration / completed_syncs.count
    end
  end
end
