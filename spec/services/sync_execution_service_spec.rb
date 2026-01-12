require "rails_helper"

RSpec.describe SyncExecutionService do
  let(:service) { described_class.new }
  let(:plugin_name) { "example" }

  describe "#execute" do
    context "when plugin is not found" do
      it "returns error result with not_found type" do
        result = service.execute(plugin_name: "nonexistent")

        expect(result[:success]).to be false
        expect(result[:plugin_name]).to eq("nonexistent")
        expect(result[:error_type]).to eq(:not_found)
        expect(result[:error]).to include("not found")
      end
    end

    context "when plugin is not enabled" do
      before do
        create(:plugin_configuration, plugin_name: plugin_name, enabled: false)
      end

      it "returns error result with not_enabled type" do
        result = service.execute(plugin_name: plugin_name)

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:not_enabled)
        expect(result[:error]).to include("not enabled")
      end
    end

    context "when plugin has no configuration" do
      it "returns error result with not_enabled type" do
        result = service.execute(plugin_name: plugin_name)

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:not_enabled)
      end
    end

    context "when plugin is enabled but not configured" do
      before do
        create(:plugin_configuration, plugin_name: plugin_name, enabled: true, credentials: nil)
      end

      it "returns error result with not_configured type" do
        result = service.execute(plugin_name: plugin_name)

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:not_configured)
        expect(result[:error]).to include("not configured")
      end
    end

    context "when plugin is enabled and configured" do
      before do
        create(:plugin_configuration,
               plugin_name: plugin_name,
               enabled: true,
               credentials: { api_key: "test_key" }.to_json)
      end

      it "executes the sync and returns success" do
        result = service.execute(plugin_name: plugin_name)

        expect(result[:success]).to be true
        expect(result[:plugin_name]).to eq(plugin_name)
        expect(result[:sync_history_id]).to be_present
        expect(result[:data]).to include(success: true)
      end

      it "creates a sync history record" do
        expect {
          service.execute(plugin_name: plugin_name)
        }.to change(SyncHistory, :count).by(1)
      end

      it "marks sync history as completed" do
        result = service.execute(plugin_name: plugin_name)

        history = SyncHistory.find(result[:sync_history_id])
        expect(history.status).to eq("completed")
        expect(history.completed_at).to be_present
      end
    end

    context "when sync raises an exception" do
      before do
        create(:plugin_configuration,
               plugin_name: plugin_name,
               enabled: true,
               credentials: { api_key: "test_key" }.to_json)

        # Mock the plugin to raise an error during sync
        allow_any_instance_of(ExamplePlugin).to receive(:sync).and_raise(StandardError, "API connection failed")
      end

      it "returns error result with execution_error type" do
        result = service.execute(plugin_name: plugin_name)

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:execution_error)
        expect(result[:error]).to eq("API connection failed")
      end
    end
  end

  describe "#execute_all" do
    context "with no enabled plugins" do
      it "returns empty array" do
        results = service.execute_all
        expect(results).to eq([])
      end
    end

    context "with multiple plugins" do
      before do
        create(:plugin_configuration,
               plugin_name: plugin_name,
               enabled: true,
               credentials: { api_key: "test" }.to_json)
        create(:plugin_configuration,
               plugin_name: "disabled_plugin",
               enabled: false)
      end

      it "executes sync for enabled plugins only" do
        results = service.execute_all

        expect(results.count).to eq(1)
        expect(results.first[:plugin_name]).to eq(plugin_name)
      end
    end

    context "with multiple enabled plugins" do
      before do
        # Only ExamplePlugin is registered, so we test with one enabled
        create(:plugin_configuration,
               plugin_name: plugin_name,
               enabled: true,
               credentials: { api_key: "test" }.to_json)
      end

      it "returns results for each plugin" do
        results = service.execute_all

        expect(results).to be_an(Array)
        expect(results.count).to eq(1)
        expect(results.first[:success]).to be true
      end
    end
  end

  describe "#execute_all_with_summary" do
    before do
      create(:plugin_configuration,
             plugin_name: plugin_name,
             enabled: true,
             credentials: { api_key: "test" }.to_json)
    end

    it "returns aggregated summary" do
      summary = service.execute_all_with_summary

      expect(summary[:total]).to eq(1)
      expect(summary[:successful]).to eq(1)
      expect(summary[:failed]).to eq(0)
      expect(summary[:skipped]).to eq(0)
      expect(summary[:results]).to be_an(Array)
    end

    context "with mixed results" do
      before do
        # Add a second enabled plugin that will fail validation (not configured)
        create(:plugin_configuration,
               plugin_name: "unconfigured_plugin",
               enabled: true,
               credentials: nil)
      end

      it "counts successful and skipped correctly" do
        summary = service.execute_all_with_summary

        # unconfigured_plugin isn't in registry, so it will be not_found
        # Only example plugin will be in results from enabled query
        expect(summary[:total]).to eq(2)
        expect(summary[:successful]).to eq(1)
      end
    end
  end

  describe "error classes" do
    it "defines SyncError base class" do
      expect(SyncExecutionService::SyncError).to be < StandardError
    end

    it "defines PluginNotEnabledError" do
      expect(SyncExecutionService::PluginNotEnabledError).to be < SyncExecutionService::SyncError
    end

    it "defines PluginNotConfiguredError" do
      expect(SyncExecutionService::PluginNotConfiguredError).to be < SyncExecutionService::SyncError
    end
  end
end
