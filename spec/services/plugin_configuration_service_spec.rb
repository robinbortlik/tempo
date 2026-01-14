require "rails_helper"

RSpec.describe PluginConfigurationService do
  # Use ExamplePlugin which exists from Phase 2
  let(:plugin_name) { "example" }
  let(:service) { described_class.new(plugin_name: plugin_name) }

  describe "#initialize" do
    it "accepts a valid plugin name" do
      expect { described_class.new(plugin_name: "example") }.not_to raise_error
    end

    it "raises NotFoundError for unknown plugin" do
      expect { described_class.new(plugin_name: "nonexistent") }
        .to raise_error(PluginRegistry::NotFoundError)
    end

    it "stores the plugin class" do
      expect(service.plugin_class).to eq(ExamplePlugin)
    end
  end

  describe "#configuration" do
    context "when no configuration exists" do
      it "returns a new unpersisted record" do
        config = service.configuration
        expect(config).to be_a(PluginConfiguration)
        expect(config).not_to be_persisted
        expect(config.plugin_name).to eq(plugin_name)
      end
    end

    context "when configuration exists" do
      let!(:existing) { create(:plugin_configuration, plugin_name: plugin_name) }

      it "returns the existing record" do
        config = service.configuration
        expect(config).to eq(existing)
        expect(config).to be_persisted
      end
    end
  end

  describe "#enabled?" do
    context "when not configured" do
      it "returns false" do
        expect(service.enabled?).to be false
      end
    end

    context "when configured but disabled" do
      before { create(:plugin_configuration, plugin_name: plugin_name, enabled: false) }

      it "returns false" do
        expect(service.enabled?).to be false
      end
    end

    context "when configured and enabled" do
      before { create(:plugin_configuration, plugin_name: plugin_name, enabled: true) }

      it "returns true" do
        expect(service.enabled?).to be true
      end
    end
  end

  describe "#configured?" do
    context "when no configuration exists" do
      it "returns false" do
        expect(service.configured?).to be false
      end
    end

    context "when configuration exists but no credentials" do
      before { create(:plugin_configuration, plugin_name: plugin_name, credentials: nil) }

      it "returns false" do
        expect(service.configured?).to be false
      end
    end

    context "when configuration exists with credentials" do
      before do
        create(:plugin_configuration, plugin_name: plugin_name, credentials: { api_key: "secret" }.to_json)
      end

      it "returns true" do
        expect(service.configured?).to be true
      end
    end
  end

  describe "#enable!" do
    context "when no configuration exists" do
      it "creates configuration and enables it" do
        result = service.enable!
        expect(result[:success]).to be true
        expect(result[:configuration]).to be_persisted
        expect(result[:configuration].enabled).to be true
      end
    end

    context "when configuration exists" do
      let!(:config) { create(:plugin_configuration, plugin_name: plugin_name, enabled: false) }

      it "enables the existing configuration" do
        result = service.enable!
        expect(result[:success]).to be true
        expect(config.reload.enabled).to be true
      end
    end
  end

  describe "#disable!" do
    context "when configuration exists and is enabled" do
      let!(:config) { create(:plugin_configuration, plugin_name: plugin_name, enabled: true) }

      it "disables the configuration" do
        result = service.disable!
        expect(result[:success]).to be true
        expect(config.reload.enabled).to be false
      end
    end

    context "when no configuration exists" do
      it "creates disabled configuration" do
        result = service.disable!
        expect(result[:success]).to be true
        expect(result[:configuration].enabled).to be false
      end
    end
  end

  describe "#update_credentials" do
    context "when no existing credentials" do
      it "stores new credentials" do
        result = service.update_credentials(api_key: "secret123", account_id: "acc_001")
        expect(result[:success]).to be true

        config = result[:configuration]
        expect(config.credentials_hash["api_key"]).to eq("secret123")
        expect(config.credentials_hash["account_id"]).to eq("acc_001")
      end
    end

    context "when credentials already exist" do
      before do
        create(:plugin_configuration, plugin_name: plugin_name, credentials: { api_key: "old_key" }.to_json)
      end

      it "merges with existing credentials" do
        result = service.update_credentials(secret_token: "new_token")
        expect(result[:success]).to be true

        config = result[:configuration]
        expect(config.credentials_hash["api_key"]).to eq("old_key")
        expect(config.credentials_hash["secret_token"]).to eq("new_token")
      end

      it "overwrites matching keys" do
        result = service.update_credentials(api_key: "new_key")
        expect(result[:success]).to be true

        config = result[:configuration]
        expect(config.credentials_hash["api_key"]).to eq("new_key")
      end
    end
  end

  describe "#replace_credentials" do
    before do
      create(:plugin_configuration, plugin_name: plugin_name, credentials: { old_key: "old_value" }.to_json)
    end

    it "replaces all credentials" do
      result = service.replace_credentials(new_key: "new_value")
      expect(result[:success]).to be true

      config = result[:configuration]
      expect(config.credentials_hash).to eq({ "new_key" => "new_value" })
      expect(config.credentials_hash["old_key"]).to be_nil
    end
  end

  describe "#clear_credentials!" do
    before do
      create(:plugin_configuration, plugin_name: plugin_name, credentials: { api_key: "secret" }.to_json)
    end

    it "clears all credentials" do
      result = service.clear_credentials!
      expect(result[:success]).to be true
      expect(result[:configuration].credentials).to be_nil
    end
  end

  describe "#update_settings" do
    context "when no existing settings" do
      it "stores new settings" do
        result = service.update_settings(sync_interval: "daily", max_records: 100)
        expect(result[:success]).to be true

        config = result[:configuration]
        expect(config.settings_hash["sync_interval"]).to eq("daily")
        expect(config.settings_hash["max_records"]).to eq(100)
      end
    end

    context "when settings already exist" do
      before do
        create(:plugin_configuration, plugin_name: plugin_name, settings: { sync_interval: "weekly" }.to_json)
      end

      it "merges with existing settings" do
        result = service.update_settings(max_records: 50)
        expect(result[:success]).to be true

        config = result[:configuration]
        expect(config.settings_hash["sync_interval"]).to eq("weekly")
        expect(config.settings_hash["max_records"]).to eq(50)
      end
    end
  end

  describe "#replace_settings" do
    before do
      create(:plugin_configuration, plugin_name: plugin_name, settings: { old_setting: "old_value" }.to_json)
    end

    it "replaces all settings" do
      result = service.replace_settings(new_setting: "new_value")
      expect(result[:success]).to be true

      config = result[:configuration]
      expect(config.settings_hash).to eq({ "new_setting" => "new_value" })
    end
  end

  describe "#clear_settings!" do
    before do
      create(:plugin_configuration, plugin_name: plugin_name, settings: { setting: "value" }.to_json)
    end

    it "clears all settings" do
      result = service.clear_settings!
      expect(result[:success]).to be true
      expect(result[:configuration].settings).to be_nil
    end
  end

  describe "#summary" do
    context "when not configured" do
      it "returns summary with default values" do
        summary = service.summary
        expect(summary[:plugin_name]).to eq("example")
        expect(summary[:plugin_version]).to eq(ExamplePlugin.version)
        expect(summary[:plugin_description]).to eq(ExamplePlugin.description)
        expect(summary[:enabled]).to be false
        expect(summary[:configured]).to be false
        expect(summary[:has_settings]).to be false
      end
    end

    context "when fully configured" do
      before do
        create(:plugin_configuration,
               plugin_name: plugin_name,
               enabled: true,
               credentials: { api_key: "secret" }.to_json,
               settings: { interval: "daily" }.to_json)
      end

      it "returns complete summary" do
        summary = service.summary
        expect(summary[:enabled]).to be true
        expect(summary[:configured]).to be true
        expect(summary[:has_settings]).to be true
        expect(summary[:created_at]).to be_present
        expect(summary[:updated_at]).to be_present
      end
    end
  end

  describe ".all_plugins_summary" do
    it "returns summary for all registered plugins" do
      summaries = described_class.all_plugins_summary
      expect(summaries).to be_an(Array)
      expect(summaries.length).to eq(PluginRegistry.all.length)
      expect(summaries.first).to include(:plugin_name, :enabled, :configured)
    end
  end

  describe ".enabled_plugins" do
    before do
      create(:plugin_configuration, plugin_name: plugin_name, enabled: true)
      create(:plugin_configuration, plugin_name: "disabled_plugin", enabled: false)
    end

    it "returns only enabled plugin configurations" do
      enabled = described_class.enabled_plugins
      expect(enabled.count).to eq(1)
      expect(enabled.first.plugin_name).to eq(plugin_name)
    end
  end
end
