require "rails_helper"

RSpec.describe ExamplePlugin::MockBankApiClient do
  let(:api_key) { "test_api_key_12345" }
  let(:account_id) { "ACC_001" }
  let(:client) { described_class.new(api_key: api_key, account_id: account_id) }

  describe "#initialize" do
    it "stores api_key and account_id" do
      expect(client.api_key).to eq(api_key)
      expect(client.account_id).to eq(account_id)
    end

    it "generates account_id from api_key if not provided" do
      client = described_class.new(api_key: api_key)
      expect(client.account_id).to start_with("MOCK_")
    end
  end

  describe "#valid_credentials?" do
    it "returns true for valid api_key (8+ chars)" do
      expect(client.valid_credentials?).to be true
    end

    it "returns false for short api_key" do
      client = described_class.new(api_key: "short")
      expect(client.valid_credentials?).to be false
    end

    it "returns false for blank api_key" do
      client = described_class.new(api_key: "")
      expect(client.valid_credentials?).to be false
    end
  end

  describe "#account_info" do
    let(:info) { client.account_info }

    it "returns account details hash" do
      expect(info).to be_a(Hash)
      expect(info[:account_id]).to eq(account_id)
      expect(info[:account_name]).to eq("Business Account")
      expect(info[:currency]).to eq("EUR")
    end

    it "includes balance" do
      expect(info[:balance]).to be_a(Float)
      expect(info[:balance]).to be > 0
    end

    it "includes IBAN" do
      expect(info[:iban]).to be_present
    end
  end

  describe "#transactions" do
    let(:from_date) { Date.current - 7 }
    let(:to_date) { Date.current }

    it "returns array of transaction hashes" do
      transactions = client.transactions(from_date: from_date, to_date: to_date)

      expect(transactions).to be_an(Array)
      transactions.each do |txn|
        expect(txn[:id]).to be_present
        expect(txn[:date]).to be_a(Date)
        expect(txn[:amount]).to be_a(Float)
        expect(txn[:currency]).to eq("EUR")
        expect(txn[:counterparty]).to be_present
        expect(txn[:type]).to be_in(%w[credit debit])
      end
    end

    it "returns transactions within date range" do
      transactions = client.transactions(from_date: from_date, to_date: to_date)

      transactions.each do |txn|
        expect(txn[:date]).to be >= from_date
        expect(txn[:date]).to be <= to_date
      end
    end

    it "respects limit parameter" do
      transactions = client.transactions(from_date: from_date, to_date: to_date, limit: 2)

      expect(transactions.length).to be <= 2
    end

    it "returns deterministic results for same date range" do
      first_call = client.transactions(from_date: from_date, to_date: to_date)
      second_call = client.transactions(from_date: from_date, to_date: to_date)

      expect(first_call.map { |t| t[:id] }).to eq(second_call.map { |t| t[:id] })
    end

    it "generates unique transaction IDs" do
      transactions = client.transactions(from_date: from_date - 30, to_date: to_date)
      ids = transactions.map { |t| t[:id] }

      expect(ids.uniq.length).to eq(ids.length)
    end

    it "includes both income and expense transactions" do
      # Use longer period to ensure variety
      transactions = client.transactions(from_date: from_date - 60, to_date: to_date, limit: 100)

      types = transactions.map { |t| t[:type] }.uniq
      expect(types).to include("credit")
      expect(types).to include("debit")
    end
  end
end
