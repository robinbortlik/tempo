require "rails_helper"

RSpec.describe ExchangeRateFetchJob do
  describe "#perform" do
    let(:date) { Date.current }
    let(:rates_data) do
      [
        { currency: "EUR", rate: 25.125, amount: 1, date: date },
        { currency: "USD", rate: 23.456, amount: 1, date: date }
      ]
    end

    before do
      # Create plugin configuration (required for SyncExecutionService)
      create(:plugin_configuration,
             plugin_name: "cnb_exchange_rate",
             enabled: true)

      # Stub the CNB API client
      allow_any_instance_of(CnbExchangeRatePlugin::ApiClient).to receive(:fetch).and_return(rates_data)
    end

    it "creates exchange rates via the CNB plugin" do
      expect { described_class.perform_now }.to change(ExchangeRate, :count).by(2)

      eur_rate = ExchangeRate.find_by(quote_currency: "EUR", date: date)
      expect(eur_rate.rate.to_f).to eq(25.125)
      expect(eur_rate.amount).to eq(1)
    end

    it "is idempotent - re-running does not create duplicates" do
      described_class.perform_now
      expect(ExchangeRate.count).to eq(2)

      described_class.perform_now
      expect(ExchangeRate.count).to eq(2)
    end

    it "updates existing rates with new values" do
      create(:exchange_rate, quote_currency: "EUR", rate: 24.000, amount: 1, date: date)

      expect { described_class.perform_now }.to change(ExchangeRate, :count).by(1)

      eur_rate = ExchangeRate.find_by(quote_currency: "EUR", date: date)
      expect(eur_rate.rate.to_f).to eq(25.125)
    end

    it "creates SyncHistory record" do
      expect { described_class.perform_now }.to change(SyncHistory, :count).by(1)

      history = SyncHistory.last
      expect(history.plugin_name).to eq("cnb_exchange_rate")
      expect(history.status).to eq("completed")
    end

    context "when plugin is not enabled" do
      before do
        PluginConfiguration.find_by(plugin_name: "cnb_exchange_rate").update!(enabled: false)
      end

      it "logs error and does not create records" do
        expect(Rails.logger).to receive(:error).with(/CNB exchange rate sync failed/)

        expect { described_class.perform_now }.not_to change(ExchangeRate, :count)
      end
    end

    context "when API fetch fails" do
      before do
        allow_any_instance_of(CnbExchangeRatePlugin::ApiClient).to receive(:fetch)
          .and_raise(CnbExchangeRatePlugin::ApiClient::FetchError.new("API error"))
      end

      it "logs error and creates failed SyncHistory" do
        expect(Rails.logger).to receive(:error).with(/CNB exchange rate sync failed/)

        expect { described_class.perform_now }.not_to change(ExchangeRate, :count)

        history = SyncHistory.last
        expect(history.status).to eq("failed")
      end
    end
  end
end
