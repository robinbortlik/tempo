# Example bank plugin demonstrating the complete plugin interface.
# This serves as both a working reference implementation and documentation
# for developers creating new plugins.
#
# Features demonstrated:
# - Credential and setting field definitions
# - API client instantiation from credentials
# - Transaction fetching with date filtering
# - Deduplication via external_id
# - Audit trail integration
# - Error handling patterns
#
# Usage:
#   # Manual sync (for testing)
#   plugin = ExamplePlugin.new
#   result = plugin.sync
#
#   # Via SyncExecutionService (production)
#   SyncExecutionService.new.execute(plugin_name: "example")
#
class ExamplePlugin < BasePlugin
  # Load the mock API client
  require_relative "example_plugin/mock_bank_api_client"

  # Plugin identity - used for registration and configuration lookup
  def self.name
    "example"
  end

  def self.version
    "2.0.0"
  end

  def self.description
    "Example bank integration plugin - demonstrates the plugin interface with mock bank data"
  end

  # Credential fields shown in the configuration UI
  # Users enter their bank API credentials here
  # @return [Array<Hash>] field definitions
  def self.credential_fields
    [
      {
        name: "api_key",
        label: "API Key",
        type: "password",
        required: true,
        description: "Your bank API key (minimum 8 characters)"
      },
      {
        name: "account_id",
        label: "Account ID",
        type: "text",
        required: false,
        description: "Specific account to sync (optional, uses default if empty)"
      }
    ]
  end

  # Setting fields for sync behavior configuration
  # @return [Array<Hash>] field definitions
  def self.setting_fields
    [
      {
        name: "sync_from_date",
        label: "Sync from date",
        type: "date",
        required: false,
        description: "Only import transactions after this date (defaults to 30 days ago)"
      },
      {
        name: "import_limit",
        label: "Import limit",
        type: "number",
        required: false,
        description: "Maximum transactions to import per sync (default: 100)"
      },
      {
        name: "default_currency",
        label: "Default currency",
        type: "text",
        required: false,
        description: "Currency code for transactions (default: EUR)"
      }
    ]
  end

  # Main sync method - fetches transactions from the bank and creates MoneyTransaction records
  # Called by sync_with_audit which handles SyncHistory lifecycle and audit context
  #
  # @return [Hash] result with :success, :records_processed, :records_created, :records_updated, or :error
  def sync
    # Validate credentials before proceeding
    client = build_api_client
    unless client.valid_credentials?
      return { success: false, error: "Invalid API credentials - key must be at least 8 characters" }
    end

    # Fetch transactions from the bank API
    from_date = sync_from_date
    to_date = Date.current
    limit = import_limit

    transactions = client.transactions(
      from_date: from_date,
      to_date: to_date,
      limit: limit
    )

    # Process each transaction
    stats = process_transactions(transactions)

    {
      success: true,
      records_processed: stats[:records_processed],
      records_created: stats[:records_created],
      records_updated: stats[:records_updated],
      date_range: { from: from_date, to: to_date },
      account_info: client.account_info
    }
  end

  private

  # Build the API client with configured credentials
  # @return [MockBankApiClient] configured client instance
  def build_api_client
    MockBankApiClient.new(
      api_key: credentials["api_key"] || "",
      account_id: credentials["account_id"]
    )
  end

  # Determine the sync start date from settings or default
  # @return [Date] start date for transaction fetch
  def sync_from_date
    if settings["sync_from_date"].present?
      Date.parse(settings["sync_from_date"])
    else
      30.days.ago.to_date
    end
  rescue ArgumentError
    30.days.ago.to_date
  end

  # Get import limit from settings or default
  # @return [Integer] maximum transactions to import
  def import_limit
    limit = settings["import_limit"].to_i
    limit.positive? ? limit : 100
  end

  # Get default currency from settings or default
  # @return [String] currency code
  def default_currency
    settings["default_currency"].presence || "EUR"
  end

  # Process transactions and create/update MoneyTransaction records
  # @param transactions [Array<Hash>] transactions from the API
  # @return [Hash] processing statistics
  def process_transactions(transactions)
    stats = { records_processed: 0, records_created: 0, records_updated: 0 }

    transactions.each do |txn|
      stats[:records_processed] += 1

      existing = find_existing_transaction(txn[:id])

      if existing
        if transaction_changed?(existing, txn)
          update_transaction(existing, txn)
          stats[:records_updated] += 1
        end
      else
        create_transaction(txn)
        stats[:records_created] += 1
      end
    end

    stats
  end

  # Find an existing transaction by external_id
  # @param external_id [String] the bank's transaction ID
  # @return [MoneyTransaction, nil]
  def find_existing_transaction(external_id)
    MoneyTransaction.find_by(source: self.class.name, external_id: external_id)
  end

  # Check if transaction data has changed (would need update)
  # @param existing [MoneyTransaction] existing record
  # @param txn [Hash] new transaction data
  # @return [Boolean]
  def transaction_changed?(existing, txn)
    existing.amount != txn[:amount] ||
      existing.description != txn[:description] ||
      existing.counterparty != txn[:counterparty]
  end

  # Create a new MoneyTransaction from bank transaction data
  # @param txn [Hash] transaction from API
  # @return [MoneyTransaction]
  def create_transaction(txn)
    MoneyTransaction.create!(
      source: self.class.name,
      external_id: txn[:id],
      amount: txn[:amount],
      currency: txn[:currency] || default_currency,
      transacted_on: txn[:date],
      transaction_type: txn[:type] == "credit" ? :income : :expense,
      description: txn[:description],
      counterparty: txn[:counterparty],
      reference: txn[:reference],
      raw_data: txn.to_json
    )
  end

  # Update an existing MoneyTransaction with new data
  # @param existing [MoneyTransaction] record to update
  # @param txn [Hash] new transaction data
  # @return [MoneyTransaction]
  def update_transaction(existing, txn)
    existing.update!(
      amount: txn[:amount],
      description: txn[:description],
      counterparty: txn[:counterparty],
      reference: txn[:reference],
      raw_data: txn.to_json
    )
    existing
  end
end
