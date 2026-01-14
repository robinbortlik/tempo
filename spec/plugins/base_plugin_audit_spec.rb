require "rails_helper"

RSpec.describe BasePlugin, "audit integration" do
  # Create a test plugin that creates MoneyTransaction during sync
  let(:test_plugin_class) do
    Class.new(BasePlugin) do
      def self.name
        "test_audit_plugin"
      end

      def self.version
        "1.0.0"
      end

      def self.description
        "Test plugin for audit integration"
      end

      def sync
        # Create a transaction during sync
        MoneyTransaction.create!(
          source: self.class.name,
          amount: 100.00,
          currency: "EUR",
          transacted_on: Date.current,
          transaction_type: :income
        )

        { success: true, records_processed: 1, records_created: 1, records_updated: 0 }
      end
    end
  end

  before do
    # Register the test plugin
    allow(PluginRegistry).to receive(:find!).with("test_audit_plugin").and_return(test_plugin_class)

    # Create configuration for the plugin
    create(:plugin_configuration,
           plugin_name: "test_audit_plugin",
           enabled: true,
           credentials: { api_key: "test" }.to_json)

    # Clean state
    Current.reset
  end

  after do
    Current.reset
  end

  describe "#sync_with_audit" do
    it "sets audit context during sync" do
      plugin = test_plugin_class.new

      captured_source = nil
      captured_sync_id = nil

      allow(MoneyTransaction).to receive(:create!).and_wrap_original do |method, *args|
        captured_source = Current.audit_source
        captured_sync_id = Current.audit_sync_history_id
        method.call(*args)
      end

      result = plugin.sync_with_audit

      expect(captured_source).to eq("test_audit_plugin")
      expect(captured_sync_id).to be_present
      expect(result[:success]).to be true
    end

    it "creates sync history before sync" do
      plugin = test_plugin_class.new

      expect {
        plugin.sync_with_audit
      }.to change(SyncHistory, :count).by(1)
    end

    it "returns sync history id in result" do
      plugin = test_plugin_class.new

      result = plugin.sync_with_audit

      expect(result[:sync_history_id]).to be_present
      expect(SyncHistory.find(result[:sync_history_id])).to be_present
    end

    it "marks sync as completed on success" do
      plugin = test_plugin_class.new

      result = plugin.sync_with_audit

      history = SyncHistory.find(result[:sync_history_id])
      expect(history.status).to eq("completed")
      expect(history.completed_at).to be_present
    end

    it "marks sync as failed on exception" do
      failing_plugin = Class.new(test_plugin_class) do
        def sync
          raise "Sync failed!"
        end
      end

      plugin = failing_plugin.new

      expect {
        plugin.sync_with_audit
      }.to raise_error("Sync failed!")

      history = SyncHistory.last
      expect(history.status).to eq("failed")
      expect(history.error_message).to eq("Sync failed!")
    end

    it "restores audit context after sync" do
      Current.audit_source = "original"

      plugin = test_plugin_class.new
      plugin.sync_with_audit

      expect(Current.audit_source).to eq("original")
    end

    it "creates audit log entries with correct source" do
      plugin = test_plugin_class.new

      expect {
        plugin.sync_with_audit
      }.to change(DataAuditLog, :count).by(1)

      log = DataAuditLog.last
      expect(log.source).to eq("test_audit_plugin")
      expect(log.action).to eq("create_action")
      expect(log.auditable_type).to eq("MoneyTransaction")
    end

    it "links audit entries to sync history" do
      plugin = test_plugin_class.new

      result = plugin.sync_with_audit

      log = DataAuditLog.last
      expect(log.sync_history_id).to eq(result[:sync_history_id])
    end
  end
end
