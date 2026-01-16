# Fetches exchange rates from Czech National Bank API
#
# Usage:
#   client = CnbApiClient.new
#   rates = client.fetch(date: Date.current)
#   # => [{ currency: "EUR", rate: 25.125, amount: 1, date: Date.current }, ...]
#
class CnbApiClient
  class FetchError < StandardError; end

  BASE_URL = "https://api.cnb.cz/cnbapi/exrates/daily".freeze
  MAX_RETRIES = 3
  RETRY_BASE_DELAY = 1

  def fetch(date: Date.current)
    response = fetch_with_retry(date)
    parse_response(response, date)
  end

  private

  def fetch_with_retry(date)
    retries = 0

    begin
      uri = build_uri(date)
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise FetchError, "HTTP error: #{response.code} #{response.message}"
      end

      response.body
    rescue StandardError => e
      retries += 1
      if retries <= MAX_RETRIES
        delay = RETRY_BASE_DELAY * (2**(retries - 1))
        Rails.logger.error("CNB API fetch attempt #{retries} failed: #{e.message}. Retrying in #{delay}s...")
        sleep(delay)
        retry
      else
        Rails.logger.error("CNB API fetch failed after #{MAX_RETRIES} attempts: #{e.message}")
        raise FetchError, "Failed to fetch CNB rates after #{MAX_RETRIES} attempts: #{e.message}"
      end
    end
  end

  def build_uri(date)
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(date: date.strftime("%Y-%m-%d"), lang: "EN")
    uri
  end

  def parse_response(body, date)
    data = JSON.parse(body)
    rates = data["rates"] || []

    rates.map do |rate_data|
      {
        currency: rate_data["currencyCode"],
        rate: rate_data["rate"],
        amount: rate_data["amount"],
        date: date
      }
    end
  end
end
