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

  # Define credential fields for configuration UI
  # @return [Array<Hash>] field definitions
  def self.credential_fields
    [
      { name: "api_key", label: "API Key", type: "password", required: true,
        description: "Your API key from the external service" },
      { name: "account_id", label: "Account ID", type: "text", required: false,
        description: "Optional account identifier" }
    ]
  end

  # Define setting fields for configuration UI
  # @return [Array<Hash>] field definitions
  def self.setting_fields
    [
      { name: "sync_from_date", label: "Sync from date", type: "date", required: false,
        description: "Only import transactions after this date" },
      { name: "import_limit", label: "Import limit", type: "number", required: false,
        description: "Maximum number of records to import per sync" }
    ]
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
