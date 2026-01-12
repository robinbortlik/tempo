# Plugin registry for discovering and listing available plugins from app/plugins/.
#
# Provides class methods to:
#   - .all              - Returns array of all plugin classes
#   - .find(name)       - Returns single plugin class by name, or nil
#   - .find!(name)      - Returns plugin class or raises NotFoundError
#   - .registered_names - Returns array of all plugin names
#   - .metadata         - Returns array of hashes with plugin info
#   - .reload!          - Clears cache for development/testing
#
# Usage:
#   PluginRegistry.all
#   # => [ExamplePlugin, ...]
#
#   PluginRegistry.find("example")
#   # => ExamplePlugin
#
#   PluginRegistry.metadata
#   # => [{ name: "example", version: "1.0.0", description: "...", class: ExamplePlugin }]
#
class PluginRegistry
  # Error raised when a plugin is not found
  class NotFoundError < StandardError; end

  class << self
    # Returns array of all plugin classes that inherit from BasePlugin
    # @return [Array<Class>] array of plugin classes
    def all
      @plugins ||= discover_plugins
    end

    # Clears the plugin cache - useful for development and testing
    # @return [void]
    def reload!
      @plugins = nil
    end

    # Finds a plugin by name (case-insensitive)
    # @param name [String] the plugin name to find
    # @return [Class, nil] the plugin class or nil if not found
    def find(name)
      return nil if name.nil?
      all.find { |plugin| plugin.name.downcase == name.to_s.downcase }
    end

    # Finds a plugin by name or raises NotFoundError
    # @param name [String] the plugin name to find
    # @return [Class] the plugin class
    # @raise [NotFoundError] if plugin is not found
    def find!(name)
      plugin = find(name)
      raise NotFoundError, "Plugin '#{name}' not found" if plugin.nil?
      plugin
    end

    # Returns array of all registered plugin names
    # @return [Array<String>] array of plugin name strings
    def registered_names
      all.map(&:name)
    end

    # Returns array of metadata hashes for all plugins
    # @return [Array<Hash>] array of hashes with :name, :version, :description, :class keys
    def metadata
      all.map do |plugin|
        {
          name: plugin.name,
          version: plugin.version,
          description: plugin.description,
          class: plugin
        }
      end
    end

    private

    # Discovers all plugins by loading files from app/plugins/ directory
    # @return [Array<Class>] array of plugin classes
    def discover_plugins
      plugin_files.each do |file|
        load_plugin_file(file)
      end

      find_plugin_classes
    end

    # Returns list of plugin files to load (excludes base_plugin.rb and plugin_registry.rb)
    # @return [Array<String>] array of file paths
    def plugin_files
      Dir.glob(plugins_path.join("*.rb")).reject do |file|
        filename = File.basename(file)
        filename == "base_plugin.rb" || filename == "plugin_registry.rb"
      end
    end

    # Path to the plugins directory
    # @return [Pathname] path to app/plugins/
    def plugins_path
      Rails.root.join("app", "plugins")
    end

    # Loads a plugin file safely, logging errors
    # @param file [String] path to the plugin file
    # @return [void]
    def load_plugin_file(file)
      require_dependency file
    rescue StandardError => e
      Rails.logger.error "Failed to load plugin file #{file}: #{e.message}"
    end

    # Finds all classes that inherit from BasePlugin
    # @return [Array<Class>] array of plugin classes
    def find_plugin_classes
      ObjectSpace.each_object(Class).select do |klass|
        klass < BasePlugin
      end
    end
  end
end
