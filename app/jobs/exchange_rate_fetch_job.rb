# Fetches daily exchange rates from Czech National Bank and stores them
#
# Usage:
#   # Manual execution
#   ExchangeRateFetchJob.perform_now
#
#   # Scheduled via config/recurring.yml (production only)
#   # Runs daily at 5 PM Europe/Prague
#
class ExchangeRateFetchJob < ApplicationJob
  queue_as :default

  def perform
    rates = fetch_rates
    upsert_rates(rates) if rates.present?
  rescue CnbApiClient::FetchError => e
    Rails.logger.error("Failed to fetch exchange rates: #{e.message}")
  end

  private

  def fetch_rates
    CnbApiClient.new.fetch(date: Date.current)
  end

  def upsert_rates(rates)
    ExchangeRate.transaction do
      ExchangeRate.upsert_all(
        rates,
        unique_by: %i[currency date]
      )
    end

    Rails.logger.info("Successfully upserted #{rates.length} exchange rates for #{Date.current}")
  end
end
