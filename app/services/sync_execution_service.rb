# Service for executing plugin sync operations
#
# Usage:
#   # Execute single plugin sync
#   service = SyncExecutionService.new
#   result = service.execute(plugin_name: "example")
#   # => { success: true, plugin_name: "example", sync_history_id: 123, data: {...} }
#
#   # Execute all enabled plugins
#   results = service.execute_all
#   # => [{ success: true, plugin_name: "example", ... }, ...]
#
class SyncExecutionService
  # Custom error for sync validation failures
  class SyncError < StandardError; end
  class PluginNotEnabledError < SyncError; end
  class PluginNotConfiguredError < SyncError; end

  # Execute sync for a single plugin by name
  # @param plugin_name [String] the plugin's name
  # @return [Hash] result with :success, :plugin_name, :sync_history_id, and :data or :error
  def execute(plugin_name:)
    plugin_class = find_plugin!(plugin_name)
    validate_plugin_enabled!(plugin_name)
    validate_plugin_configured!(plugin_name)

    run_sync(plugin_class)
  rescue PluginRegistry::NotFoundError => e
    { success: false, plugin_name: plugin_name, error: e.message, error_type: :not_found }
  rescue PluginNotEnabledError => e
    { success: false, plugin_name: plugin_name, error: e.message, error_type: :not_enabled }
  rescue PluginNotConfiguredError => e
    { success: false, plugin_name: plugin_name, error: e.message, error_type: :not_configured }
  rescue StandardError => e
    { success: false, plugin_name: plugin_name, error: e.message, error_type: :execution_error }
  end

  # Execute sync for all enabled plugins
  # @return [Array<Hash>] array of results from each plugin sync
  def execute_all
    enabled_plugins.map do |config|
      execute(plugin_name: config.plugin_name)
    end
  end

  # Execute sync for all enabled and configured plugins (skip validation failures)
  # @return [Hash] aggregated results with :successful, :failed, :skipped counts
  def execute_all_with_summary
    results = execute_all

    {
      total: results.count,
      successful: results.count { |r| r[:success] },
      failed: results.count { |r| !r[:success] && r[:error_type] == :execution_error },
      skipped: results.count { |r| !r[:success] && [ :not_enabled, :not_configured ].include?(r[:error_type]) },
      results: results
    }
  end

  private

  # Find the plugin class or raise NotFoundError
  def find_plugin!(plugin_name)
    PluginRegistry.find!(plugin_name)
  end

  # Validate that the plugin is enabled
  def validate_plugin_enabled!(plugin_name)
    config = PluginConfiguration.find_by(plugin_name: plugin_name)
    unless config&.enabled?
      raise PluginNotEnabledError, "Plugin '#{plugin_name}' is not enabled"
    end
  end

  # Validate that the plugin has credentials configured (if required)
  def validate_plugin_configured!(plugin_name)
    plugin_class = PluginRegistry.find(plugin_name)
    return if plugin_class && !requires_credentials?(plugin_class)

    config = PluginConfiguration.find_by(plugin_name: plugin_name)
    unless config&.has_credentials?
      raise PluginNotConfiguredError, "Plugin '#{plugin_name}' is not configured (missing credentials)"
    end
  end

  # Check if a plugin requires credentials
  def requires_credentials?(plugin_class)
    return false unless plugin_class.respond_to?(:credential_fields)
    credential_fields = plugin_class.credential_fields
    credential_fields.present? && credential_fields.any? { |f| f[:required] }
  end

  # Returns enabled plugin configurations
  def enabled_plugins
    PluginConfiguration.enabled
  end

  # Run the actual sync operation
  # @param plugin_class [Class] the plugin class to instantiate and sync
  # @return [Hash] result hash with sync details
  def run_sync(plugin_class)
    plugin = plugin_class.new

    # Use sync_with_audit to ensure all data changes are tracked
    # This sets Current.audit_source and Current.audit_sync_history_id
    sync_result = plugin.sync_with_audit

    {
      success: sync_result[:success],
      plugin_name: plugin_class.name,
      sync_history_id: sync_result[:sync_history_id],
      data: sync_result
    }
  end
end
