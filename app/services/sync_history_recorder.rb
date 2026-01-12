# Service for recording and managing sync history entries
#
# Usage:
#   # Record a successful sync (typically called by SyncExecutionService)
#   recorder = SyncHistoryRecorder.new(plugin_name: "example")
#   history = recorder.record_start
#   # ... perform sync ...
#   recorder.record_success(history, records_processed: 10, records_created: 5, records_updated: 2)
#
#   # Record a failed sync
#   recorder.record_failure(history, error: "Connection timeout")
#
#   # Clean up orphaned pending/running syncs
#   SyncHistoryRecorder.cleanup_orphaned
#
class SyncHistoryRecorder
  attr_reader :plugin_name

  # Maximum duration before a sync is considered orphaned (stuck)
  ORPHAN_THRESHOLD = 1.hour

  def initialize(plugin_name:)
    @plugin_name = plugin_name
  end

  # Creates a new sync history entry with running status
  # @return [SyncHistory] the created record
  def record_start
    SyncHistory.create!(
      plugin_name: plugin_name,
      status: :running,
      started_at: Time.current
    )
  end

  # Marks a sync as completed with the given statistics
  # @param history [SyncHistory] the sync history record to update
  # @param stats [Hash] statistics (records_processed, records_created, records_updated)
  # @return [SyncHistory] the updated record
  def record_success(history, stats = {})
    history.update!(
      status: :completed,
      completed_at: Time.current,
      records_processed: stats[:records_processed] || 0,
      records_created: stats[:records_created] || 0,
      records_updated: stats[:records_updated] || 0
    )
    history
  end

  # Marks a sync as failed with the given error
  # @param history [SyncHistory] the sync history record to update
  # @param error [String] the error message
  # @return [SyncHistory] the updated record
  def record_failure(history, error:)
    history.update!(
      status: :failed,
      completed_at: Time.current,
      error_message: error
    )
    history
  end

  # Returns the most recent sync for this plugin
  # @return [SyncHistory, nil]
  def last_sync
    SyncHistory.for_plugin(plugin_name).order(created_at: :desc).first
  end

  # Returns the most recent successful sync for this plugin
  # @return [SyncHistory, nil]
  def last_successful_sync
    SyncHistory.for_plugin(plugin_name).successful.order(created_at: :desc).first
  end

  # Returns statistics for this plugin
  # @return [Hash]
  def stats
    SyncHistory.stats_for_plugin(plugin_name)
  end

  # Class method to clean up orphaned sync entries
  # Marks pending/running syncs older than ORPHAN_THRESHOLD as failed
  # @return [Integer] number of records cleaned up
  def self.cleanup_orphaned
    orphaned = SyncHistory.in_progress.where("started_at < ?", ORPHAN_THRESHOLD.ago)

    count = orphaned.count
    orphaned.update_all(
      status: :failed,
      completed_at: Time.current,
      error_message: "Sync timed out (orphaned process)"
    )
    count
  end

  # Class method to get all plugins with recent activity
  # @param limit [Integer] number of recent entries per plugin
  # @return [Hash] hash of plugin_name => recent sync histories
  def self.recent_by_plugin(limit: 5)
    result = {}

    SyncHistory.select(:plugin_name).distinct.pluck(:plugin_name).each do |name|
      result[name] = SyncHistory.for_plugin(name).recent.limit(limit).map(&:summary)
    end

    result
  end
end
