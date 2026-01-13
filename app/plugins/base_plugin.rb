# Base class for all plugins. Defines the contract that plugins must follow.
#
# == Plugin Contract
#
# Plugins are simple Ruby classes that extend BasePlugin. The minimal contract requires:
#
# === Required Class Methods
#
# - name        - Returns unique plugin identifier (string, lowercase with underscores)
# - version     - Returns semantic version string (e.g., "1.0.0")
# - description - Returns human-readable description for UI display
#
# === Required Instance Method
#
# - sync        - Performs the sync operation, returns result hash with :success key
#
# === Optional Class Methods
#
# - credential_fields - Array of field definitions for credential configuration UI
# - setting_fields    - Array of field definitions for settings configuration UI
#
# == Available Helpers
#
# Instance methods available in your plugin:
#
# - configuration       - Returns PluginConfiguration record for this plugin
# - credentials         - Returns decrypted credentials as Hash
# - settings            - Returns settings as Hash
# - create_sync_history - Creates SyncHistory with pending status
# - complete_sync(history, stats) - Marks sync as completed with stats
# - fail_sync(history, error) - Marks sync as failed with error message
# - sync_with_audit     - Wraps sync in audit context (used by SyncExecutionService)
#
# == Example
#
#   class MyBankPlugin < BasePlugin
#     def self.name
#       "my_bank"
#     end
#
#     def self.version
#       "1.0.0"
#     end
#
#     def self.description
#       "Sync transactions from My Bank"
#     end
#
#     def self.credential_fields
#       [{ name: "api_key", label: "API Key", type: "password", required: true }]
#     end
#
#     def sync
#       api_key = credentials["api_key"]
#       # ... fetch and process data ...
#       { success: true, records_processed: 10, records_created: 5 }
#     end
#   end
#
# == Sync Result Hash
#
# The sync method must return a Hash with at least :success key:
#
#   # Success
#   { success: true, records_processed: 10, records_created: 5, records_updated: 2 }
#
#   # Failure
#   { success: false, error: "API returned 401 Unauthorized" }
#
# == Audit Trail
#
# When sync is called via SyncExecutionService (or sync_with_audit directly),
# all data changes are automatically logged to DataAuditLog with your plugin
# name as the source. Use MoneyTransaction (which includes Auditable) for
# financial data to get automatic audit logging.
#
# See docs/PLUGIN_DEVELOPMENT.md for comprehensive documentation.
#
class BasePlugin
  class << self
    # Returns the plugin's unique identifier
    # @return [String] unique plugin name
    def name
      raise NotImplementedError, "#{self} must implement .name"
    end

    # Returns the plugin's version string
    # @return [String] semantic version (e.g., "1.0.0")
    def version
      raise NotImplementedError, "#{self} must implement .version"
    end

    # Returns a human-readable description of the plugin
    # @return [String] plugin description
    def description
      raise NotImplementedError, "#{self} must implement .description"
    end
  end

  # Performs the sync operation
  # @return [Hash] result with :success key and additional data
  def sync
    raise NotImplementedError, "#{self.class} must implement #sync"
  end

  # Returns the PluginConfiguration record for this plugin
  # @return [PluginConfiguration, nil] configuration record or nil if not found
  def configuration
    @configuration ||= PluginConfiguration.find_by(plugin_name: self.class.name)
  end

  # Returns the credentials as a parsed hash
  # @return [Hash] credentials hash or empty hash if not configured
  def credentials
    configuration&.credentials_hash || {}
  end

  # Returns the settings as a parsed hash
  # @return [Hash] settings hash or empty hash if not configured
  def settings
    configuration&.settings_hash || {}
  end

  # Creates a new SyncHistory record with pending status
  # @return [SyncHistory] the created sync history record
  def create_sync_history
    SyncHistory.create!(
      plugin_name: self.class.name,
      status: :pending,
      started_at: Time.current
    )
  end

  # Marks a sync history as completed with the given stats
  # @param sync_history [SyncHistory] the sync history to update
  # @param stats [Hash] statistics about the sync operation (records_processed, records_created, records_updated)
  # @return [SyncHistory] the updated sync history record
  def complete_sync(sync_history, stats = {})
    sync_history.update!(
      status: :completed,
      completed_at: Time.current,
      records_processed: stats[:records_processed] || 0,
      records_created: stats[:records_created] || 0,
      records_updated: stats[:records_updated] || 0
    )
    sync_history
  end

  # Marks a sync history as failed with the given error message
  # @param sync_history [SyncHistory] the sync history to update
  # @param error [String] the error message
  # @return [SyncHistory] the updated sync history record
  def fail_sync(sync_history, error)
    sync_history.update!(
      status: :failed,
      completed_at: Time.current,
      error_message: error
    )
    sync_history
  end

  # Executes the sync method within an audit context
  # This ensures all data changes are attributed to this plugin
  # @return [Hash] result from sync method
  def sync_with_audit
    sync_history = create_sync_history
    sync_history.update!(status: :running)

    Current.with_audit_context(source: self.class.name, sync_history_id: sync_history.id) do
      begin
        result = sync

        if result[:success]
          complete_sync(sync_history, result.slice(:records_processed, :records_created, :records_updated))
        else
          fail_sync(sync_history, result[:error] || "Sync returned failure")
        end

        result.merge(sync_history_id: sync_history.id)
      rescue StandardError => e
        fail_sync(sync_history, e.message)
        raise
      end
    end
  end
end
