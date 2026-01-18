require "rails_helper"

RSpec.describe CnbExchangeRatePlugin::ApiClient do
  describe "#fetch" do
    let(:client) { described_class.new }
    let(:date) { Date.new(2024, 12, 15) }

    context "when API returns valid response" do
      let(:api_response) do
        {
          "rates" => [
            { "currencyCode" => "EUR", "rate" => 25.125, "amount" => 1 },
            { "currencyCode" => "USD", "rate" => 23.456, "amount" => 1 },
            { "currencyCode" => "JPY", "rate" => 0.153, "amount" => 100 }
          ]
        }
      end

      before do
        stub_request(:get, "https://api.cnb.cz/cnbapi/exrates/daily")
          .with(query: { date: "2024-12-15", lang: "EN" })
          .to_return(status: 200, body: api_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "parses JSON response correctly" do
        result = client.fetch(date: date)

        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
      end

      it "returns normalized rate hashes" do
        result = client.fetch(date: date)

        eur_rate = result.find { |r| r[:currency] == "EUR" }
        expect(eur_rate).to eq({ currency: "EUR", rate: 25.125, amount: 1, date: date })

        jpy_rate = result.find { |r| r[:currency] == "JPY" }
        expect(jpy_rate).to eq({ currency: "JPY", rate: 0.153, amount: 100, date: date })
      end
    end

    context "when API returns network error" do
      before do
        stub_request(:get, "https://api.cnb.cz/cnbapi/exrates/daily")
          .with(query: { date: "2024-12-15", lang: "EN" })
          .to_timeout
      end

      it "retries up to 3 times and raises error" do
        expect(Rails.logger).to receive(:error).at_least(:once)

        expect { client.fetch(date: date) }.to raise_error(CnbExchangeRatePlugin::ApiClient::FetchError, /Failed to fetch CNB rates/)
      end
    end

    context "when API returns HTTP error" do
      before do
        stub_request(:get, "https://api.cnb.cz/cnbapi/exrates/daily")
          .with(query: { date: "2024-12-15", lang: "EN" })
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "retries and raises error after max attempts" do
        expect(Rails.logger).to receive(:error).at_least(:once)

        expect { client.fetch(date: date) }.to raise_error(CnbExchangeRatePlugin::ApiClient::FetchError)
      end
    end
  end
end
