require "rails_helper"

RSpec.describe CnbExchangeRatePlugin do
  describe "class methods" do
    it "returns plugin name" do
      expect(described_class.name).to eq("cnb_exchange_rate")
    end

    it "returns version" do
      expect(described_class.version).to match(/\d+\.\d+\.\d+/)
    end

    it "returns description" do
      expect(described_class.description).to be_present
    end

    it "has no required credential_fields" do
      fields = described_class.credential_fields
      expect(fields).to eq([])
    end

    it "defines setting_fields" do
      fields = described_class.setting_fields
      expect(fields).to be_an(Array)

      backfill_field = fields.find { |f| f[:name] == "backfill_days" }
      expect(backfill_field).to be_present
      expect(backfill_field[:type]).to eq("number")
      expect(backfill_field[:required]).to be false
    end
  end

  describe "#sync" do
    let(:plugin) { described_class.new }
    let(:mock_rates) do
      [
        { currency: "EUR", rate: 25.125, amount: 1, date: Date.current },
        { currency: "USD", rate: 23.456, amount: 1, date: Date.current },
        { currency: "GBP", rate: 29.789, amount: 1, date: Date.current }
      ]
    end

    before do
      ExchangeRate.delete_all
      SyncHistory.delete_all
      Current.reset

      # Stub the CNB API client
      allow_any_instance_of(CnbExchangeRatePlugin::ApiClient).to receive(:fetch).and_return(mock_rates)
    end

    context "without configuration (plugin works without credentials)" do
      it "returns success result" do
        result = plugin.sync

        expect(result[:success]).to be true
        expect(result[:records_processed]).to eq(3)
        expect(result[:records_created]).to eq(3)
      end

      it "creates ExchangeRate records" do
        expect {
          plugin.sync
        }.to change(ExchangeRate, :count).by(3)
      end
    end

    context "with configuration" do
      before do
        create(:plugin_configuration,
               plugin_name: "cnb_exchange_rate",
               enabled: true,
               credentials: nil,
               settings: nil)
      end

      it "returns success result" do
        result = plugin.sync

        expect(result[:success]).to be true
        expect(result[:records_processed]).to eq(3)
        expect(result[:records_created]).to eq(3)
      end

      it "creates ExchangeRate records with correct data" do
        plugin.sync

        eur_rate = ExchangeRate.find_by(quote_currency: "EUR", date: Date.current)
        expect(eur_rate).to be_present
        expect(eur_rate.rate).to eq(25.125)
        expect(eur_rate.amount).to eq(1)
      end

      it "returns dates_fetched in result" do
        result = plugin.sync

        expect(result[:dates_fetched]).to eq([ Date.current.to_s ])
      end
    end

    context "deduplication" do
      it "does not create duplicates on re-sync" do
        plugin.sync
        first_count = ExchangeRate.count

        plugin.sync
        second_count = ExchangeRate.count

        expect(second_count).to eq(first_count)
      end

      it "reports records_updated when rate changes" do
        plugin.sync

        updated_rates = [
          { currency: "EUR", rate: 25.999, amount: 1, date: Date.current },
          { currency: "USD", rate: 23.456, amount: 1, date: Date.current },
          { currency: "GBP", rate: 29.789, amount: 1, date: Date.current }
        ]
        allow_any_instance_of(CnbExchangeRatePlugin::ApiClient).to receive(:fetch).and_return(updated_rates)

        result = plugin.sync

        expect(result[:records_updated]).to eq(1)
        expect(ExchangeRate.find_by(quote_currency: "EUR").rate).to eq(25.999)
      end
    end

    context "with backfill_days setting" do
      before do
        create(:plugin_configuration,
               plugin_name: "cnb_exchange_rate",
               enabled: true,
               settings: { backfill_days: "3" }.to_json)
      end

      it "fetches rates for multiple days" do
        expect_any_instance_of(CnbExchangeRatePlugin::ApiClient).to receive(:fetch).exactly(4).times.and_return(mock_rates)

        result = plugin.sync

        expect(result[:dates_fetched].length).to eq(4)
      end
    end

    context "error handling" do
      it "returns failure when API fails" do
        allow_any_instance_of(CnbExchangeRatePlugin::ApiClient).to receive(:fetch)
          .and_raise(CnbExchangeRatePlugin::ApiClient::FetchError.new("Network error"))

        result = plugin.sync

        expect(result[:success]).to be false
        expect(result[:error]).to include("Network error")
      end

      it "returns failure for unexpected errors" do
        allow_any_instance_of(CnbExchangeRatePlugin::ApiClient).to receive(:fetch)
          .and_raise(StandardError.new("Something went wrong"))

        result = plugin.sync

        expect(result[:success]).to be false
        expect(result[:error]).to include("Unexpected error")
      end
    end

    context "empty response" do
      it "handles empty rates gracefully" do
        allow_any_instance_of(CnbExchangeRatePlugin::ApiClient).to receive(:fetch).and_return([])

        result = plugin.sync

        expect(result[:success]).to be true
        expect(result[:records_processed]).to eq(0)
        expect(result[:records_created]).to eq(0)
      end
    end
  end
end
