require "rails_helper"

RSpec.describe PluginConfiguration, type: :model do
  describe "validations" do
    it "requires plugin_name to be present" do
      config = build(:plugin_configuration, plugin_name: nil)
      expect(config).not_to be_valid
      expect(config.errors[:plugin_name]).to include("can't be blank")
    end

    it "requires plugin_name to be unique" do
      create(:plugin_configuration, plugin_name: "unique_plugin")
      duplicate = build(:plugin_configuration, plugin_name: "unique_plugin")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:plugin_name]).to include("has already been taken")
    end
  end

  describe "scopes" do
    let!(:enabled_config) { create(:plugin_configuration, plugin_name: "enabled_plugin", enabled: true, credentials: nil) }
    let!(:disabled_config) { create(:plugin_configuration, plugin_name: "disabled_plugin", enabled: false, credentials: nil) }
    let!(:configured_config) do
      create(:plugin_configuration, plugin_name: "configured_plugin", credentials: { key: "value" }.to_json)
    end

    describe ".enabled" do
      it "returns only enabled configurations" do
        expect(described_class.enabled).to include(enabled_config)
        expect(described_class.enabled).not_to include(disabled_config)
      end
    end

    describe ".disabled" do
      it "returns only disabled configurations" do
        expect(described_class.disabled).to include(disabled_config)
        expect(described_class.disabled).not_to include(enabled_config)
      end
    end

    describe ".configured" do
      it "returns configurations with credentials" do
        expect(described_class.configured).to include(configured_config)
        expect(described_class.configured).not_to include(enabled_config)
      end
    end
  end

  describe "#credentials_hash" do
    it "returns empty hash when credentials is nil" do
      config = build(:plugin_configuration, credentials: nil)
      expect(config.credentials_hash).to eq({})
    end

    it "returns empty hash when credentials is empty" do
      config = build(:plugin_configuration, credentials: "")
      expect(config.credentials_hash).to eq({})
    end

    it "returns parsed JSON hash" do
      config = build(:plugin_configuration, credentials: { api_key: "secret" }.to_json)
      expect(config.credentials_hash).to eq({ "api_key" => "secret" })
    end

    it "returns empty hash for invalid JSON" do
      config = build(:plugin_configuration)
      # Force bypass encryption for test
      allow(config).to receive(:credentials).and_return("invalid json")
      expect(config.credentials_hash).to eq({})
    end
  end

  describe "#settings_hash" do
    it "returns empty hash when settings is nil" do
      config = build(:plugin_configuration, settings: nil)
      expect(config.settings_hash).to eq({})
    end

    it "returns empty hash when settings is empty" do
      config = build(:plugin_configuration, settings: "")
      expect(config.settings_hash).to eq({})
    end

    it "returns parsed JSON hash" do
      config = build(:plugin_configuration, settings: { interval: "daily" }.to_json)
      expect(config.settings_hash).to eq({ "interval" => "daily" })
    end
  end

  describe "#has_credentials?" do
    it "returns false when credentials is nil" do
      config = build(:plugin_configuration, credentials: nil)
      expect(config.has_credentials?).to be false
    end

    it "returns false when credentials is empty" do
      config = build(:plugin_configuration, credentials: "")
      expect(config.has_credentials?).to be false
    end

    it "returns true when credentials present" do
      config = build(:plugin_configuration, credentials: { key: "value" }.to_json)
      expect(config.has_credentials?).to be true
    end
  end

  describe "#has_settings?" do
    it "returns false when settings is nil" do
      config = build(:plugin_configuration, settings: nil)
      expect(config.has_settings?).to be false
    end

    it "returns true when settings present" do
      config = build(:plugin_configuration, settings: { key: "value" }.to_json)
      expect(config.has_settings?).to be true
    end
  end

  describe "encryption" do
    it "encrypts credentials at rest" do
      config = create(:plugin_configuration, plugin_name: "test_encryption", credentials: { api_key: "super_secret" }.to_json)

      # The raw database value should be encrypted (not plain JSON)
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT credentials FROM plugin_configurations WHERE id = #{config.id}"
      ).first["credentials"]

      expect(raw_value).not_to include("super_secret")
      expect(config.credentials_hash["api_key"]).to eq("super_secret")
    end
  end
end
