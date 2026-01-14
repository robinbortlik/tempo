require "rails_helper"

RSpec.describe FioBankPlugin do
  describe "class methods" do
    it "returns plugin name" do
      expect(described_class.name).to eq("fio_bank")
    end

    it "returns version" do
      expect(described_class.version).to eq("1.0.0")
    end

    it "returns description" do
      expect(described_class.description).to be_present
    end

    it "defines credential_fields with api_token" do
      fields = described_class.credential_fields
      api_token_field = fields.find { |f| f[:name] == "api_token" }

      expect(api_token_field).to be_present
      expect(api_token_field[:type]).to eq("password")
      expect(api_token_field[:required]).to be true
    end

    it "defines setting_fields with sync_from_date and cron_schedule" do
      fields = described_class.setting_fields

      sync_from_date = fields.find { |f| f[:name] == "sync_from_date" }
      expect(sync_from_date).to be_present
      expect(sync_from_date[:type]).to eq("date")

      cron_schedule = fields.find { |f| f[:name] == "cron_schedule" }
      expect(cron_schedule).to be_present
      expect(cron_schedule[:type]).to eq("text")
    end
  end

  describe "#sync" do
    let(:plugin) { described_class.new }

    before do
      MoneyTransaction.delete_all
      SyncHistory.delete_all
      Current.reset
    end

    context "without configuration" do
      it "fails with missing token error" do
        result = plugin.sync

        expect(result[:success]).to be false
        expect(result[:error]).to include("API token is required")
      end
    end

    context "with valid configuration" do
      let(:income_transaction) do
        instance_double(FioAPI::Transaction,
          transaction_id: 12345,
          date: Date.current.to_s,
          amount: 1000.0,
          currency: "CZK",
          account: "123456789",
          account_name: "Test Company",
          bank_code: "0100",
          bank_name: "KB",
          vs: "2026-001",
          ks: nil,
          ss: nil,
          user_identification: "Test Company",
          message_for_recipient: "Payment for invoice",
          transaction_type: "Příchozí platba",
          comment: "Test Company"
        )
      end

      let(:expense_transaction) do
        instance_double(FioAPI::Transaction,
          transaction_id: 12346,
          date: Date.current.to_s,
          amount: -500.0,
          currency: "CZK",
          account: "987654321",
          account_name: "Expense Corp",
          bank_code: "0300",
          bank_name: "CSOB",
          vs: nil,
          ks: nil,
          ss: nil,
          user_identification: nil,
          message_for_recipient: "Office supplies",
          transaction_type: "Odchozí platba",
          comment: nil
        )
      end

      let(:account_double) do
        instance_double(FioAPI::Account, account_id: "123456789")
      end

      let(:response_double) do
        instance_double(FioAPI::ListResponseDeserializer,
          transactions: [ income_transaction, expense_transaction ],
          account: account_double
        )
      end

      before do
        create(:plugin_configuration,
               plugin_name: "fio_bank",
               enabled: true,
               credentials: { api_token: "test_token_123" }.to_json,
               settings: { sync_from_date: 7.days.ago.to_date.to_s }.to_json)

        allow(FioAPI).to receive(:token=)
        list_double = instance_double(FioAPI::List)
        allow(FioAPI::List).to receive(:new).and_return(list_double)
        allow(list_double).to receive(:by_date_range)
        allow(list_double).to receive(:response).and_return(response_double)
      end

      it "returns success result" do
        result = plugin.sync

        expect(result[:success]).to be true
        expect(result[:records_processed]).to eq(2)
        expect(result[:records_created]).to eq(2)
      end

      it "creates MoneyTransaction records" do
        expect {
          plugin.sync
        }.to change(MoneyTransaction, :count).by(2)
      end

      it "sets transaction_type to income for credits" do
        plugin.sync

        income_txn = MoneyTransaction.find_by(external_id: "12345")
        expect(income_txn.transaction_type).to eq("income")
      end

      it "sets transaction_type to expense for debits" do
        plugin.sync

        expense_txn = MoneyTransaction.find_by(external_id: "12346")
        expect(expense_txn.transaction_type).to eq("expense")
      end

      it "stores reference from variable symbol" do
        plugin.sync

        txn = MoneyTransaction.find_by(external_id: "12345")
        expect(txn.reference).to eq("2026-001")
      end
    end

    context "deduplication" do
      let(:transaction) do
        instance_double(FioAPI::Transaction,
          transaction_id: 99999,
          date: Date.current.to_s,
          amount: 500.0,
          currency: "CZK",
          account: nil,
          account_name: "Test",
          bank_code: nil,
          bank_name: nil,
          vs: nil,
          ks: nil,
          ss: nil,
          user_identification: nil,
          message_for_recipient: "Test payment",
          transaction_type: "Příchozí platba",
          comment: nil
        )
      end

      let(:account_double) do
        instance_double(FioAPI::Account, account_id: "123456789")
      end

      let(:response_double) do
        instance_double(FioAPI::ListResponseDeserializer,
          transactions: [ transaction ],
          account: account_double
        )
      end

      before do
        create(:plugin_configuration,
               plugin_name: "fio_bank",
               enabled: true,
               credentials: { api_token: "test_token_123" }.to_json)

        allow(FioAPI).to receive(:token=)
        list_double = instance_double(FioAPI::List)
        allow(FioAPI::List).to receive(:new).and_return(list_double)
        allow(list_double).to receive(:by_date_range)
        allow(list_double).to receive(:response).and_return(response_double)
      end

      it "does not create duplicates on re-sync" do
        plugin.sync
        first_count = MoneyTransaction.count

        plugin.sync
        second_count = MoneyTransaction.count

        expect(second_count).to eq(first_count)
      end
    end

    context "with empty API response" do
      let(:account_double) do
        instance_double(FioAPI::Account, account_id: nil)
      end

      let(:response_double) do
        instance_double(FioAPI::ListResponseDeserializer,
          transactions: [],
          account: account_double
        )
      end

      before do
        create(:plugin_configuration,
               plugin_name: "fio_bank",
               enabled: true,
               credentials: { api_token: "invalid_token" }.to_json)

        allow(FioAPI).to receive(:token=)
        list_double = instance_double(FioAPI::List)
        allow(FioAPI::List).to receive(:new).and_return(list_double)
        allow(list_double).to receive(:by_date_range)
        allow(list_double).to receive(:response).and_return(response_double)
      end

      it "fails with empty response error" do
        result = plugin.sync

        expect(result[:success]).to be false
        expect(result[:error]).to include("FIO API returned empty response")
      end
    end
  end
end
