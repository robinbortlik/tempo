# Example plugin demonstrating the BasePlugin interface.
# Copy this as a starting point for new plugins.
#
# Required class methods:
#   - self.name        - unique plugin identifier (string)
#   - self.version     - semantic version (e.g., "1.0.0")
#   - self.description - human-readable description
#
# Required instance method:
#   - sync             - performs sync, returns { success: true/false, ... }
#
# Available helpers:
#   - configuration      - PluginConfiguration record for this plugin
#   - credentials        - parsed credentials hash (from configuration.credentials_hash)
#   - settings           - parsed settings hash (from configuration.settings_hash)
#   - create_sync_history - creates SyncHistory with pending status
#   - complete_sync(history, stats) - marks sync as completed with stats
#   - fail_sync(history, error) - marks sync as failed with error message
#
# Usage:
#   plugin = ExamplePlugin.new
#   result = plugin.sync
#   # => { success: true, records_processed: 0 }
#
class ExamplePlugin < BasePlugin
  def self.name
    "example"
  end

  def self.version
    "1.0.0"
  end

  def self.description
    "Example plugin for documentation purposes"
  end

  def sync
    history = create_sync_history

    begin
      # Your sync logic here:
      # 1. Fetch data from external API using credentials
      #    api_key = credentials["api_key"]
      #    response = SomeApiClient.new(api_key).fetch_transactions
      #
      # 2. Process and store data
      #    response.each do |transaction|
      #      MoneyTransaction.create!(...)
      #    end
      #
      # 3. Return stats
      #    records_processed = response.count

      records_processed = 0
      records_created = 0
      records_updated = 0

      complete_sync(history,
        records_processed: records_processed,
        records_created: records_created,
        records_updated: records_updated
      )

      { success: true, records_processed: records_processed }
    rescue StandardError => e
      fail_sync(history, e.message)
      { success: false, error: e.message }
    end
  end
end
