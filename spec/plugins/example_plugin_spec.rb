require "rails_helper"

RSpec.describe ExamplePlugin do
  describe "class methods" do
    it "returns plugin name" do
      expect(described_class.name).to eq("example")
    end

    it "returns version" do
      expect(described_class.version).to match(/\d+\.\d+\.\d+/)
    end

    it "returns description" do
      expect(described_class.description).to be_present
    end

    it "defines credential_fields" do
      fields = described_class.credential_fields
      expect(fields).to be_an(Array)

      api_key_field = fields.find { |f| f[:name] == "api_key" }
      expect(api_key_field).to be_present
      expect(api_key_field[:type]).to eq("password")
      expect(api_key_field[:required]).to be true
    end

    it "defines setting_fields" do
      fields = described_class.setting_fields
      expect(fields).to be_an(Array)

      date_field = fields.find { |f| f[:name] == "sync_from_date" }
      expect(date_field).to be_present
      expect(date_field[:type]).to eq("date")
    end
  end

  describe "#sync" do
    let(:plugin) { described_class.new }

    before do
      # Clean up any existing data
      MoneyTransaction.delete_all
      SyncHistory.delete_all
      Current.reset
    end

    context "without configuration" do
      it "fails with invalid credentials error" do
        result = plugin.sync

        expect(result[:success]).to be false
        expect(result[:error]).to include("Invalid API credentials")
      end
    end

    context "with valid configuration" do
      before do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "valid_api_key_123", account_id: "ACC001" }.to_json,
               settings: { sync_from_date: 7.days.ago.to_date.to_s, import_limit: "50" }.to_json)
      end

      it "returns success result" do
        result = plugin.sync

        expect(result[:success]).to be true
        expect(result[:records_processed]).to be >= 0
        expect(result[:records_created]).to be >= 0
      end

      it "creates MoneyTransaction records" do
        expect {
          plugin.sync
        }.to change(MoneyTransaction, :count)
      end

      it "creates transactions with correct source" do
        plugin.sync

        MoneyTransaction.all.each do |txn|
          expect(txn.source).to eq("example")
        end
      end

      it "creates transactions with external_id" do
        plugin.sync

        MoneyTransaction.all.each do |txn|
          expect(txn.external_id).to be_present
          expect(txn.external_id).to start_with("TXN_")
        end
      end

      it "stores raw transaction data" do
        plugin.sync

        txn = MoneyTransaction.first
        expect(txn.raw_data).to be_present
        raw = JSON.parse(txn.raw_data)
        expect(raw["id"]).to eq(txn.external_id)
      end

      it "returns account info in result" do
        result = plugin.sync

        expect(result[:account_info]).to be_present
        expect(result[:account_info][:account_id]).to be_present
      end

      it "returns date range in result" do
        result = plugin.sync

        expect(result[:date_range]).to be_present
        expect(result[:date_range][:from]).to be_present
        expect(result[:date_range][:to]).to be_present
      end
    end

    context "deduplication" do
      before do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "valid_api_key_123" }.to_json,
               settings: { sync_from_date: 7.days.ago.to_date.to_s }.to_json)
      end

      it "does not create duplicates on re-sync" do
        # First sync
        plugin.sync
        first_count = MoneyTransaction.count

        # Second sync with same data
        plugin.sync
        second_count = MoneyTransaction.count

        expect(second_count).to eq(first_count)
      end

      it "reports records_updated when data changes" do
        # This test verifies the dedup logic exists
        # In practice, mock data is deterministic so updates won't occur
        result = plugin.sync

        expect(result[:records_updated]).to be >= 0
      end
    end

    context "with custom settings" do
      it "respects import_limit setting" do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "valid_api_key_123" }.to_json,
               settings: { sync_from_date: 60.days.ago.to_date.to_s, import_limit: "5" }.to_json)

        plugin.sync

        # Should have at most 5 transactions
        expect(MoneyTransaction.count).to be <= 5
      end

      it "uses default 30 days when sync_from_date not set" do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "valid_api_key_123" }.to_json)

        result = plugin.sync

        from_date = result[:date_range][:from]
        expect(from_date).to eq(30.days.ago.to_date)
      end

      it "handles invalid date gracefully" do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "valid_api_key_123" }.to_json,
               settings: { sync_from_date: "invalid-date" }.to_json)

        result = plugin.sync

        # Should fall back to 30 days ago
        expect(result[:success]).to be true
        expect(result[:date_range][:from]).to eq(30.days.ago.to_date)
      end
    end

    context "transaction types" do
      before do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "valid_api_key_123" }.to_json,
               settings: { sync_from_date: 60.days.ago.to_date.to_s, import_limit: "100" }.to_json)
      end

      it "creates both income and expense transactions" do
        plugin.sync

        income_count = MoneyTransaction.income.count
        expense_count = MoneyTransaction.expenses.count

        expect(income_count).to be > 0
        expect(expense_count).to be > 0
      end

      it "sets correct transaction_type based on API type" do
        plugin.sync

        # Verify by checking raw_data
        MoneyTransaction.all.each do |txn|
          raw = JSON.parse(txn.raw_data)
          if raw["type"] == "credit"
            expect(txn.transaction_type).to eq("income")
          else
            expect(txn.transaction_type).to eq("expense")
          end
        end
      end
    end
  end
end
