require 'rails_helper'

RSpec.describe BasePlugin do
  include ActiveSupport::Testing::TimeHelpers

  describe "interface contract" do
    describe ".name" do
      it "raises NotImplementedError" do
        expect { described_class.name }.to raise_error(NotImplementedError)
      end

      it "includes class name in error message" do
        expect { described_class.name }.to raise_error(/BasePlugin must implement \.name/)
      end
    end

    describe ".version" do
      it "raises NotImplementedError" do
        expect { described_class.version }.to raise_error(NotImplementedError)
      end

      it "includes class name in error message" do
        expect { described_class.version }.to raise_error(/BasePlugin must implement \.version/)
      end
    end

    describe ".description" do
      it "raises NotImplementedError" do
        expect { described_class.description }.to raise_error(NotImplementedError)
      end

      it "includes class name in error message" do
        expect { described_class.description }.to raise_error(/BasePlugin must implement \.description/)
      end
    end

    describe "#sync" do
      it "raises NotImplementedError" do
        expect { described_class.new.sync }.to raise_error(NotImplementedError)
      end

      it "includes class name in error message" do
        expect { described_class.new.sync }.to raise_error(/BasePlugin must implement #sync/)
      end
    end
  end

  describe "with proper subclass" do
    let(:plugin_class) do
      Class.new(BasePlugin) do
        def self.name
          "test_plugin"
        end

        def self.version
          "1.0.0"
        end

        def self.description
          "Test plugin for specs"
        end

        def sync
          { success: true, records_processed: 0 }
        end
      end
    end

    let(:plugin) { plugin_class.new }

    describe "class methods" do
      it "returns the plugin name" do
        expect(plugin_class.name).to eq("test_plugin")
      end

      it "returns the plugin version" do
        expect(plugin_class.version).to eq("1.0.0")
      end

      it "returns the plugin description" do
        expect(plugin_class.description).to eq("Test plugin for specs")
      end
    end

    describe "instance methods" do
      it "can call sync" do
        result = plugin.sync
        expect(result).to eq({ success: true, records_processed: 0 })
      end
    end
  end

  describe "partial implementation" do
    context "when only name is implemented" do
      let(:partial_plugin_class) do
        Class.new(BasePlugin) do
          def self.name
            "partial_plugin"
          end
        end
      end

      it "returns name correctly" do
        expect(partial_plugin_class.name).to eq("partial_plugin")
      end

      it "raises NotImplementedError for version" do
        expect { partial_plugin_class.version }.to raise_error(NotImplementedError)
      end

      it "raises NotImplementedError for description" do
        expect { partial_plugin_class.description }.to raise_error(NotImplementedError)
      end

      it "raises NotImplementedError for sync" do
        expect { partial_plugin_class.new.sync }.to raise_error(NotImplementedError)
      end
    end
  end

  describe "helper methods" do
    let(:plugin_class) do
      Class.new(BasePlugin) do
        def self.name
          "test_plugin"
        end

        def self.version
          "1.0.0"
        end

        def self.description
          "Test plugin"
        end

        def sync
          { success: true }
        end
      end
    end

    let(:plugin) { plugin_class.new }

    describe "#configuration" do
      context "when no configuration exists" do
        it "returns nil" do
          expect(plugin.configuration).to be_nil
        end
      end

      context "when configuration exists" do
        let!(:config) do
          create(:plugin_configuration,
            plugin_name: "test_plugin",
            credentials: { api_key: "secret123" }.to_json,
            settings: { sync_interval: 300 }.to_json
          )
        end

        it "returns the configuration record" do
          expect(plugin.configuration).to eq(config)
        end

        it "caches the configuration" do
          2.times { plugin.configuration }
          # Should only query once due to memoization
          expect(plugin.instance_variable_get(:@configuration)).to eq(config)
        end
      end
    end

    describe "#credentials" do
      context "when no configuration exists" do
        it "returns empty hash" do
          expect(plugin.credentials).to eq({})
        end
      end

      context "when configuration exists" do
        before do
          create(:plugin_configuration,
            plugin_name: "test_plugin",
            credentials: { api_key: "secret123", api_secret: "supersecret" }.to_json
          )
        end

        it "returns parsed credentials hash" do
          expect(plugin.credentials).to eq({ "api_key" => "secret123", "api_secret" => "supersecret" })
        end
      end

      context "when credentials are nil" do
        before do
          create(:plugin_configuration,
            plugin_name: "test_plugin",
            credentials: nil
          )
        end

        it "returns empty hash" do
          expect(plugin.credentials).to eq({})
        end
      end
    end

    describe "#settings" do
      context "when no configuration exists" do
        it "returns empty hash" do
          expect(plugin.settings).to eq({})
        end
      end

      context "when configuration exists" do
        before do
          create(:plugin_configuration,
            plugin_name: "test_plugin",
            settings: { sync_interval: 300, batch_size: 100 }.to_json
          )
        end

        it "returns parsed settings hash" do
          expect(plugin.settings).to eq({ "sync_interval" => 300, "batch_size" => 100 })
        end
      end

      context "when settings are nil" do
        before do
          create(:plugin_configuration,
            plugin_name: "test_plugin",
            settings: nil
          )
        end

        it "returns empty hash" do
          expect(plugin.settings).to eq({})
        end
      end
    end

    describe "#create_sync_history" do
      it "creates a SyncHistory record" do
        expect { plugin.create_sync_history }.to change(SyncHistory, :count).by(1)
      end

      it "sets the plugin_name" do
        history = plugin.create_sync_history
        expect(history.plugin_name).to eq("test_plugin")
      end

      it "sets status to pending" do
        history = plugin.create_sync_history
        expect(history.status).to eq("pending")
      end

      it "sets started_at to current time" do
        frozen_time = Time.zone.local(2026, 1, 12, 12, 0, 0)
        travel_to(frozen_time) do
          history = plugin.create_sync_history
          expect(history.started_at).to eq(frozen_time)
        end
      end
    end

    describe "#complete_sync" do
      let!(:sync_history) { plugin.create_sync_history }

      it "updates status to completed" do
        plugin.complete_sync(sync_history, records_processed: 10)
        expect(sync_history.reload.status).to eq("completed")
      end

      it "sets completed_at to current time" do
        frozen_time = Time.zone.local(2026, 1, 12, 12, 0, 0)
        travel_to(frozen_time) do
          plugin.complete_sync(sync_history, records_processed: 10)
          expect(sync_history.reload.completed_at).to eq(frozen_time)
        end
      end

      it "sets records_processed from stats" do
        plugin.complete_sync(sync_history, records_processed: 25)
        expect(sync_history.reload.records_processed).to eq(25)
      end

      it "sets records_created from stats" do
        plugin.complete_sync(sync_history, records_created: 15)
        expect(sync_history.reload.records_created).to eq(15)
      end

      it "sets records_updated from stats" do
        plugin.complete_sync(sync_history, records_updated: 8)
        expect(sync_history.reload.records_updated).to eq(8)
      end

      it "returns the updated sync history" do
        result = plugin.complete_sync(sync_history, records_processed: 10)
        expect(result).to eq(sync_history)
      end

      it "defaults stats to 0 when not provided" do
        plugin.complete_sync(sync_history)
        history = sync_history.reload
        expect(history.records_processed).to eq(0)
        expect(history.records_created).to eq(0)
        expect(history.records_updated).to eq(0)
      end
    end

    describe "#fail_sync" do
      let!(:sync_history) { plugin.create_sync_history }

      it "updates status to failed" do
        plugin.fail_sync(sync_history, "Connection refused")
        expect(sync_history.reload.status).to eq("failed")
      end

      it "sets completed_at to current time" do
        frozen_time = Time.zone.local(2026, 1, 12, 12, 0, 0)
        travel_to(frozen_time) do
          plugin.fail_sync(sync_history, "Connection refused")
          expect(sync_history.reload.completed_at).to eq(frozen_time)
        end
      end

      it "sets error_message" do
        plugin.fail_sync(sync_history, "API rate limit exceeded")
        expect(sync_history.reload.error_message).to eq("API rate limit exceeded")
      end

      it "returns the updated sync history" do
        result = plugin.fail_sync(sync_history, "Error")
        expect(result).to eq(sync_history)
      end
    end
  end
end
