# Service for managing plugin configurations (enable/disable, credentials, settings)
#
# Usage:
#   service = PluginConfigurationService.new(plugin_name: "example")
#   service.enable!
#   service.update_credentials(api_key: "secret123")
#   service.update_settings(sync_interval: "daily")
#
class PluginConfigurationService
  attr_reader :plugin_name, :plugin_class

  # Initialize with plugin name, validates plugin exists in registry
  # @param plugin_name [String] the plugin's name
  # @raise [PluginRegistry::NotFoundError] if plugin not found
  def initialize(plugin_name:)
    @plugin_name = plugin_name
    @plugin_class = PluginRegistry.find!(plugin_name)
  end

  # Returns the configuration record, creating if needed
  # @return [PluginConfiguration] the configuration record
  def configuration
    @configuration ||= PluginConfiguration.find_or_initialize_by(plugin_name: plugin_name)
  end

  # Returns whether the plugin is currently enabled
  # @return [Boolean]
  def enabled?
    configuration.persisted? && configuration.enabled?
  end

  # Returns whether the plugin has credentials configured
  # @return [Boolean]
  def configured?
    configuration.persisted? && configuration.credentials.present?
  end

  # Enables the plugin
  # @return [Hash] result with :success and :configuration or :errors
  def enable!
    configuration.enabled = true
    save_configuration
  end

  # Disables the plugin
  # @return [Hash] result with :success and :configuration or :errors
  def disable!
    configuration.enabled = false
    save_configuration
  end

  # Updates the plugin's credentials (merges with existing)
  # @param credentials [Hash] credentials to store (will be encrypted)
  # @return [Hash] result with :success and :configuration or :errors
  def update_credentials(credentials)
    existing = configuration.credentials_hash
    merged = existing.merge(credentials.stringify_keys)
    configuration.credentials = merged.to_json
    save_configuration
  end

  # Replaces all credentials with new values
  # @param credentials [Hash] credentials to store (will be encrypted)
  # @return [Hash] result with :success and :configuration or :errors
  def replace_credentials(credentials)
    configuration.credentials = credentials.to_json
    save_configuration
  end

  # Clears all stored credentials
  # @return [Hash] result with :success and :configuration or :errors
  def clear_credentials!
    configuration.credentials = nil
    save_configuration
  end

  # Updates the plugin's settings (merges with existing)
  # @param settings [Hash] settings to store
  # @return [Hash] result with :success and :configuration or :errors
  def update_settings(settings)
    existing = configuration.settings_hash
    merged = existing.merge(settings.stringify_keys)
    configuration.settings = merged.to_json
    save_configuration
  end

  # Replaces all settings with new values
  # @param settings [Hash] settings to store
  # @return [Hash] result with :success and :configuration or :errors
  def replace_settings(settings)
    configuration.settings = settings.to_json
    save_configuration
  end

  # Clears all stored settings
  # @return [Hash] result with :success and :configuration or :errors
  def clear_settings!
    configuration.settings = nil
    save_configuration
  end

  # Returns summary for UI display
  # @return [Hash] configuration summary
  def summary
    {
      plugin_name: plugin_name,
      plugin_version: plugin_class.version,
      plugin_description: plugin_class.description,
      enabled: enabled?,
      configured: configured?,
      has_settings: configuration.settings.present?,
      created_at: configuration.created_at,
      updated_at: configuration.updated_at
    }
  end

  # Class method to get summary for all registered plugins
  # @return [Array<Hash>] array of plugin summaries
  def self.all_plugins_summary
    PluginRegistry.all.map do |plugin_class|
      new(plugin_name: plugin_class.name).summary
    end
  end

  # Class method to get only enabled plugins
  # @return [Array<PluginConfiguration>] enabled plugin configurations
  def self.enabled_plugins
    PluginConfiguration.where(enabled: true)
  end

  private

  def save_configuration
    if configuration.save
      { success: true, configuration: configuration }
    else
      { success: false, errors: configuration.errors.full_messages }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end
end
