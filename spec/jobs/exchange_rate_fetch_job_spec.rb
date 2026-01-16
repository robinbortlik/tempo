require "rails_helper"

RSpec.describe ExchangeRateFetchJob do
  describe "#perform" do
    let(:date) { Date.new(2024, 12, 15) }
    let(:rates_data) do
      [
        { currency: "EUR", rate: 25.125, amount: 1, date: date },
        { currency: "USD", rate: 23.456, amount: 1, date: date }
      ]
    end
    let(:cnb_client) { instance_double(CnbApiClient) }

    before do
      allow(CnbApiClient).to receive(:new).and_return(cnb_client)
      allow(cnb_client).to receive(:fetch).and_return(rates_data)
    end

    it "upserts exchange rates correctly" do
      expect { described_class.perform_now }.to change(ExchangeRate, :count).by(2)

      eur_rate = ExchangeRate.find_by(currency: "EUR", date: date)
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
      create(:exchange_rate, currency: "EUR", rate: 24.000, amount: 1, date: date)

      expect { described_class.perform_now }.to change(ExchangeRate, :count).by(1)

      eur_rate = ExchangeRate.find_by(currency: "EUR", date: date)
      expect(eur_rate.rate.to_f).to eq(25.125)
    end

    context "when API fetch fails" do
      before do
        allow(cnb_client).to receive(:fetch).and_raise(CnbApiClient::FetchError.new("API error"))
      end

      it "logs error and does not create records" do
        expect(Rails.logger).to receive(:error).with(/Failed to fetch exchange rates/)

        expect { described_class.perform_now }.not_to change(ExchangeRate, :count)
      end
    end
  end
end
