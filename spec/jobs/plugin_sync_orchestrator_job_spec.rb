require "rails_helper"

RSpec.describe PluginSyncOrchestratorJob do
  include ActiveSupport::Testing::TimeHelpers

  describe "#perform" do
    let(:sync_service) { instance_double(SyncExecutionService) }

    before do
      allow(SyncExecutionService).to receive(:new).and_return(sync_service)
    end

    context "when there are no enabled plugins" do
      it "does not execute any syncs" do
        expect(sync_service).not_to receive(:execute)
        described_class.perform_now
      end
    end

    context "with enabled plugins and matching cron schedule" do
      let!(:config) do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "test_key" }.to_json,
               settings: { cron_schedule: "* * * * *" }.to_json)
      end

      it "executes sync for plugins with matching schedule" do
        # Freeze at start of minute for cron to match
        travel_to Time.zone.local(2024, 6, 15, 10, 0, 0) do
          expect(sync_service).to receive(:execute).with(plugin_name: "example")
          described_class.perform_now
        end
      end
    end

    context "with enabled plugin but non-matching cron schedule" do
      let!(:config) do
        # Schedule for minute 30 only
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "test_key" }.to_json,
               settings: { cron_schedule: "30 * * * *" }.to_json)
      end

      it "skips plugins whose schedule does not match current time" do
        # Freeze at minute 0, not minute 30
        travel_to Time.zone.local(2024, 6, 15, 10, 0, 0) do
          expect(sync_service).not_to receive(:execute)
          described_class.perform_now
        end
      end
    end

    context "with enabled plugin but blank cron schedule" do
      let!(:config) do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "test_key" }.to_json,
               settings: { cron_schedule: "" }.to_json)
      end

      it "skips plugins with blank cron schedule" do
        expect(sync_service).not_to receive(:execute)
        described_class.perform_now
      end
    end

    context "with enabled plugin but invalid cron schedule" do
      let!(:config) do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "test_key" }.to_json,
               settings: { cron_schedule: "invalid cron" }.to_json)
      end

      it "skips plugins with invalid cron expressions" do
        expect(sync_service).not_to receive(:execute)
        described_class.perform_now
      end
    end

    context "when sync execution raises an error" do
      let!(:config) do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "test_key" }.to_json,
               settings: { cron_schedule: "* * * * *" }.to_json)
      end

      let!(:other_config) do
        create(:plugin_configuration,
               plugin_name: "other_plugin",
               enabled: true,
               credentials: { api_key: "other_key" }.to_json,
               settings: { cron_schedule: "* * * * *" }.to_json)
      end

      it "logs the error and continues with the next plugin" do
        travel_to Time.zone.local(2024, 6, 15, 10, 0, 0) do
          allow(sync_service).to receive(:execute).with(plugin_name: "example")
            .and_raise(StandardError, "API connection failed")
          allow(sync_service).to receive(:execute).with(plugin_name: "other_plugin")
            .and_return({ success: true })

          allow(Rails.logger).to receive(:error)

          # Should not raise error, should continue processing
          expect { described_class.perform_now }.not_to raise_error

          expect(Rails.logger).to have_received(:error).with(/Failed to sync plugin 'example': API connection failed/)
          # Should still attempt to execute the second plugin
          expect(sync_service).to have_received(:execute).with(plugin_name: "other_plugin")
        end
      end
    end

    context "with disabled plugins" do
      let!(:enabled_config) do
        create(:plugin_configuration,
               plugin_name: "example",
               enabled: true,
               credentials: { api_key: "test_key" }.to_json,
               settings: { cron_schedule: "* * * * *" }.to_json)
      end

      let!(:disabled_config) do
        create(:plugin_configuration,
               plugin_name: "disabled_plugin",
               enabled: false,
               credentials: { api_key: "other_key" }.to_json,
               settings: { cron_schedule: "* * * * *" }.to_json)
      end

      it "only processes enabled plugins" do
        travel_to Time.zone.local(2024, 6, 15, 10, 0, 0) do
          expect(sync_service).to receive(:execute).with(plugin_name: "example")
          expect(sync_service).not_to receive(:execute).with(plugin_name: "disabled_plugin")
          described_class.perform_now
        end
      end
    end
  end
end
