require "rails_helper"

RSpec.describe "ExamplePlugin integration", type: :integration do
  describe "full sync workflow via SyncExecutionService" do
    let(:service) { SyncExecutionService.new }

    before do
      MoneyTransaction.delete_all
      SyncHistory.delete_all
      DataAuditLog.delete_all
      Current.reset
    end

    context "with disabled plugin" do
      before do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: false,
               credentials: { api_key: "valid_key_123" }.to_json)
      end

      it "returns not_enabled error" do
        result = service.execute(plugin_name: "example")

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:not_enabled)
      end
    end

    context "with enabled but unconfigured plugin" do
      before do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: nil)
      end

      it "returns not_configured error" do
        result = service.execute(plugin_name: "example")

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:not_configured)
      end
    end

    context "with fully configured plugin" do
      before do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "valid_api_key_123" }.to_json,
               settings: { sync_from_date: 14.days.ago.to_date.to_s }.to_json)
      end

      it "executes sync successfully" do
        result = service.execute(plugin_name: "example")

        expect(result[:success]).to be true
        expect(result[:plugin_name]).to eq("example")
        expect(result[:sync_history_id]).to be_present
      end

      it "creates MoneyTransaction records" do
        expect {
          service.execute(plugin_name: "example")
        }.to change(MoneyTransaction, :count)
      end

      it "creates SyncHistory record" do
        expect {
          service.execute(plugin_name: "example")
        }.to change(SyncHistory, :count).by(1)
      end

      it "records sync stats in history" do
        result = service.execute(plugin_name: "example")

        history = SyncHistory.find(result[:sync_history_id])
        expect(history.records_processed).to be > 0
        expect(history.records_created).to be > 0
        expect(history.completed_at).to be_present
      end

      it "creates audit logs for created transactions" do
        service.execute(plugin_name: "example")

        audit_logs = DataAuditLog.for_source("example")
        expect(audit_logs.count).to be > 0
        # action_before_type_cast returns the DB value which is the enum string "create"
        expect(audit_logs.first.action_before_type_cast).to eq("create")
      end

      it "links audit logs to sync history" do
        result = service.execute(plugin_name: "example")

        audit_logs = DataAuditLog.for_sync(result[:sync_history_id])
        expect(audit_logs.count).to be > 0
      end
    end
  end
end
