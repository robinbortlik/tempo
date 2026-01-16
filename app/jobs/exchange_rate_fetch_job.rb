# Fetches daily exchange rates from Czech National Bank via the CNB plugin
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
    result = SyncExecutionService.new.execute(plugin_name: "cnb_exchange_rate")

    if result[:success]
      Rails.logger.info("CNB exchange rate sync completed: #{result[:data][:records_created]} created, #{result[:data][:records_updated]} updated")
    else
      Rails.logger.error("CNB exchange rate sync failed: #{result[:error]}")
    end
  end
end
