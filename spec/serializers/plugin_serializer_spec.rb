require "rails_helper"

RSpec.describe PluginSerializer do
  let(:plugin_summary) do
    {
      plugin_name: "example",
      plugin_version: "1.0.0",
      plugin_description: "Example plugin",
      enabled: true,
      configured: true,
      has_settings: false,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  describe "default serializer" do
    it "serializes plugin summary" do
      result = described_class.new(plugin_summary).serializable_hash

      expect(result["plugin_name"]).to eq("example")
      expect(result["plugin_version"]).to eq("1.0.0")
      expect(result["plugin_description"]).to eq("Example plugin")
      expect(result["enabled"]).to be true
      expect(result["configured"]).to be true
      expect(result["has_settings"]).to be false
    end

    it "formats created_at as ISO8601" do
      result = described_class.new(plugin_summary).serializable_hash

      expect(result["created_at"]).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it "formats updated_at as ISO8601" do
      result = described_class.new(plugin_summary).serializable_hash

      expect(result["updated_at"]).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it "handles nil timestamps" do
      plugin_summary[:created_at] = nil
      plugin_summary[:updated_at] = nil

      result = described_class.new(plugin_summary).serializable_hash

      expect(result["created_at"]).to be_nil
      expect(result["updated_at"]).to be_nil
    end
  end

  describe PluginSerializer::List do
    let(:sync_stats) do
      {
        "example" => {
          total_syncs: 10,
          success_rate: 95.5,
          last_sync: {
            completed_at: "2026-01-12T10:00:00Z",
            status: "completed"
          }
        }
      }
    end

    it "serializes plugin with sync stats" do
      result = described_class.new([plugin_summary], params: { sync_stats: sync_stats }).serializable_hash

      plugin = result.first
      expect(plugin["plugin_name"]).to eq("example")
      expect(plugin["plugin_version"]).to eq("1.0.0")
      expect(plugin["enabled"]).to be true
      expect(plugin["configured"]).to be true
      expect(plugin["total_syncs"]).to eq(10)
      expect(plugin["success_rate"]).to eq(95.5)
      expect(plugin["last_sync_status"]).to eq("completed")
    end

    it "handles missing sync stats" do
      result = described_class.new([plugin_summary], params: { sync_stats: {} }).serializable_hash

      plugin = result.first
      expect(plugin["total_syncs"]).to eq(0)
      expect(plugin["success_rate"]).to eq(0.0)
      expect(plugin["last_sync_at"]).to be_nil
      expect(plugin["last_sync_status"]).to be_nil
    end

    it "handles nil sync_stats param" do
      result = described_class.new([plugin_summary], params: { sync_stats: nil }).serializable_hash

      plugin = result.first
      expect(plugin["total_syncs"]).to eq(0)
      expect(plugin["success_rate"]).to eq(0.0)
    end

    it "serializes collection of plugins" do
      plugin2 = {
        plugin_name: "another",
        plugin_version: "2.0.0",
        plugin_description: "Another plugin",
        enabled: false,
        configured: false
      }

      result = described_class.new([plugin_summary, plugin2], params: { sync_stats: {} }).serializable_hash

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first["plugin_name"]).to eq("example")
      expect(result.second["plugin_name"]).to eq("another")
    end
  end
end
