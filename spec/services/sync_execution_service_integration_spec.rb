require "rails_helper"

RSpec.describe SyncExecutionService, "integration" do
  let(:service) { described_class.new }
  let(:plugin_name) { "example" }

  describe "full sync workflow" do
    let!(:configuration) do
      create(:plugin_configuration,
             plugin_name: plugin_name,
             enabled: true,
             credentials: { api_key: "integration_test_key" }.to_json,
             settings: { batch_size: 100 }.to_json)
    end

    it "executes complete sync workflow" do
      # Pre-conditions
      expect(SyncHistory.count).to eq(0)

      # Execute sync
      result = service.execute(plugin_name: plugin_name)

      # Verify result
      expect(result[:success]).to be true
      expect(result[:plugin_name]).to eq(plugin_name)

      # Verify sync history was created
      expect(SyncHistory.count).to eq(1)

      history = SyncHistory.last
      expect(history.plugin_name).to eq(plugin_name)
      expect(history.status).to eq("completed")
      expect(history.started_at).to be_present
      expect(history.completed_at).to be_present
      expect(history.error_message).to be_nil

      # Verify duration is reasonable (sync should be fast for example plugin)
      expect(history.duration).to be >= 0
      expect(history.duration).to be < 5 # Should complete in under 5 seconds
    end

    it "handles plugin accessing its configuration during sync" do
      # ExamplePlugin should be able to access credentials via BasePlugin helpers
      plugin = ExamplePlugin.new

      # Verify configuration is accessible
      expect(plugin.configuration).to eq(configuration)
      expect(plugin.credentials["api_key"]).to eq("integration_test_key")
      expect(plugin.settings["batch_size"]).to eq(100)

      # Execute sync through service
      result = service.execute(plugin_name: plugin_name)
      expect(result[:success]).to be true
    end

    it "records multiple sync runs in history" do
      3.times do
        service.execute(plugin_name: plugin_name)
      end

      expect(SyncHistory.for_plugin(plugin_name).count).to eq(3)

      # Verify recent scope works
      recent = SyncHistory.for_plugin(plugin_name).recent
      expect(recent.count).to eq(3)
      expect(recent.first.created_at).to be >= recent.last.created_at
    end
  end
end
