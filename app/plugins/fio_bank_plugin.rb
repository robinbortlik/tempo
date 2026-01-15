# FIO bank plugin for syncing transactions from FIO bank API.
#
# Usage:
#   # Manual sync (for testing)
#   plugin = FioBankPlugin.new
#   result = plugin.sync
#
#   # Via SyncExecutionService (production)
#   SyncExecutionService.new.execute(plugin_name: "fio_bank")
#
class FioBankPlugin < BasePlugin
  def self.name
    "fio_bank"
  end

  def self.version
    "1.0.0"
  end

  def self.description
    "FIO bank integration - syncs transactions and matches payments to invoices"
  end

  def self.credential_fields
    [
      {
        name: "api_token",
        label: "API Token",
        type: "password",
        required: true,
        description: "Your FIO bank API token"
      }
    ]
  end

  def self.setting_fields
    [
      {
        name: "sync_from_date",
        label: "Sync from date",
        type: "date",
        required: false,
        description: "Only import transactions after this date (defaults to 30 days ago). Note: FIO API limits to 90 days without strong authorization."
      },
      {
        name: "cron_schedule",
        label: "Sync schedule",
        type: "text",
        required: false,
        description: "Cron expression for automatic sync (e.g., '0 8 * * *' for daily at 8am)"
      }
    ]
  end

  def sync
    return { success: false, error: "API token is required" } if api_token.blank?

    from_date = sync_from_date
    to_date = Date.current

    transactions = fetch_transactions(from_date, to_date)
    stats = process_transactions(transactions)

    # Match transactions to invoices after processing
    InvoiceMatchingService.match_all

    # Update sync_from_date for next incremental fetch
    update_last_sync_date(to_date)

    {
      success: true,
      records_processed: stats[:records_processed],
      records_created: stats[:records_created],
      records_updated: stats[:records_updated],
      date_range: { from: from_date, to: to_date }
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def api_token
    credentials["api_token"]
  end

  def sync_from_date
    if settings["sync_from_date"].present?
      Date.parse(settings["sync_from_date"])
    else
      30.days.ago.to_date
    end
  rescue ArgumentError
    30.days.ago.to_date
  end

  def fetch_transactions(from_date, to_date)
    FioAPI.token = api_token
    list = FioAPI::List.new
    list.by_date_range(from_date, to_date)
    response = list.response

    # Validate API response - if account_id is nil, the API rejected the request
    if response.account.account_id.nil?
      raise "FIO API returned empty response. Check if API token is valid and date range is within 90 days."
    end

    response.transactions.map { |txn| normalize_transaction(txn) }
  end

  def normalize_transaction(txn)
    {
      id: txn.transaction_id.to_s,
      amount: txn.amount.abs,
      currency: txn.currency || "CZK",
      date: parse_date(txn.date),
      type: txn.amount >= 0 ? "credit" : "debit",
      counterparty: extract_counterparty(txn),
      reference: txn.vs&.to_s.presence,
      description: txn.message_for_recipient || txn.comment,
      raw: transaction_to_hash(txn)
    }
  end

  def parse_date(value)
    return Date.current if value.blank?
    Date.parse(value.to_s)
  rescue ArgumentError
    Date.current
  end

  def extract_counterparty(txn)
    name = txn.account_name.presence || txn.user_identification.presence || txn.comment
    account = txn.account
    bank = txn.bank_name

    [ name, account, bank ].compact.reject(&:blank?).first(2).join(" - ").presence
  end

  def transaction_to_hash(txn)
    {
      transaction_id: txn.transaction_id,
      date: txn.date,
      amount: txn.amount,
      currency: txn.currency,
      account: txn.account,
      account_name: txn.account_name,
      bank_code: txn.bank_code,
      bank_name: txn.bank_name,
      vs: txn.vs,
      ks: txn.ks,
      ss: txn.ss,
      user_identification: txn.user_identification,
      message_for_recipient: txn.message_for_recipient,
      transaction_type: txn.transaction_type,
      comment: txn.comment
    }
  end

  def process_transactions(transactions)
    stats = { records_processed: 0, records_created: 0, records_updated: 0 }

    transactions.each do |txn|
      next if txn[:id].blank?

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

  def find_existing_transaction(external_id)
    MoneyTransaction.find_by(source: self.class.name, external_id: external_id)
  end

  def transaction_changed?(existing, txn)
    existing.amount != txn[:amount] ||
      existing.description != txn[:description] ||
      existing.counterparty != txn[:counterparty]
  end

  def create_transaction(txn)
    MoneyTransaction.create!(
      source: self.class.name,
      external_id: txn[:id],
      amount: txn[:amount],
      currency: txn[:currency],
      transacted_on: txn[:date],
      transaction_type: txn[:type] == "credit" ? :income : :expense,
      description: txn[:description],
      counterparty: txn[:counterparty],
      reference: txn[:reference],
      raw_data: txn[:raw].to_json
    )
  end

  def update_transaction(existing, txn)
    existing.update!(
      amount: txn[:amount],
      description: txn[:description],
      counterparty: txn[:counterparty],
      reference: txn[:reference],
      raw_data: txn[:raw].to_json
    )
    existing
  end

  def update_last_sync_date(date)
    return unless configuration

    new_settings = settings.merge("sync_from_date" => date.to_s)
    configuration.update!(settings: new_settings.to_json)
  end
end
