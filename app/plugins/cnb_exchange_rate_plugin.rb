# CNB Exchange Rate plugin for fetching daily exchange rates from Czech National Bank.
#
# This plugin fetches exchange rates relative to CZK and stores them in the
# ExchangeRate model for use in invoice currency conversion.
#
# Unlike bank plugins that sync MoneyTransactions, this plugin syncs
# reference data (exchange rates) used for currency conversion.
#
# Usage:
#   # Manual sync (for testing)
#   plugin = CnbExchangeRatePlugin.new
#   result = plugin.sync
#
#   # Via SyncExecutionService (production)
#   SyncExecutionService.new.execute(plugin_name: "cnb_exchange_rate")
#
class CnbExchangeRatePlugin < BasePlugin
  def self.name
    "cnb_exchange_rate"
  end

  def self.version
    "1.0.0"
  end

  def self.description
    "Czech National Bank exchange rates - fetches daily rates for invoice currency conversion"
  end

  def self.credential_fields
    # CNB API is free and requires no authentication
    []
  end

  def self.setting_fields
    [
      {
        name: "backfill_days",
        label: "Backfill days",
        type: "number",
        required: false,
        description: "Number of days to backfill when syncing (default: 0, only today)"
      }
    ]
  end

  def sync
    dates_to_fetch = determine_dates_to_fetch
    stats = { records_processed: 0, records_created: 0, records_updated: 0 }

    dates_to_fetch.each do |date|
      result = fetch_and_store_rates(date)
      stats[:records_processed] += result[:processed]
      stats[:records_created] += result[:created]
      stats[:records_updated] += result[:updated]
    end

    {
      success: true,
      records_processed: stats[:records_processed],
      records_created: stats[:records_created],
      records_updated: stats[:records_updated],
      dates_fetched: dates_to_fetch.map(&:to_s)
    }
  rescue CnbApiClient::FetchError => e
    { success: false, error: e.message }
  rescue StandardError => e
    { success: false, error: "Unexpected error: #{e.message}" }
  end

  private

  def determine_dates_to_fetch
    backfill = backfill_days
    if backfill.positive?
      (Date.current - backfill.days..Date.current).to_a
    else
      [ Date.current ]
    end
  end

  def backfill_days
    days = settings["backfill_days"].to_i
    days.positive? ? days : 0
  end

  def fetch_and_store_rates(date)
    rates = api_client.fetch(date: date)
    return { processed: 0, created: 0, updated: 0 } if rates.empty?

    stats = { processed: 0, created: 0, updated: 0 }

    rates.each do |rate_data|
      stats[:processed] += 1

      existing = ExchangeRate.find_by(currency: rate_data[:currency], date: rate_data[:date])

      if existing
        if rate_changed?(existing, rate_data)
          existing.update!(rate: rate_data[:rate], amount: rate_data[:amount])
          stats[:updated] += 1
        end
      else
        ExchangeRate.create!(
          currency: rate_data[:currency],
          rate: rate_data[:rate],
          amount: rate_data[:amount],
          date: rate_data[:date]
        )
        stats[:created] += 1
      end
    end

    stats
  end

  def rate_changed?(existing, rate_data)
    existing.rate != rate_data[:rate] || existing.amount != rate_data[:amount]
  end

  def api_client
    @api_client ||= CnbApiClient.new
  end
end
