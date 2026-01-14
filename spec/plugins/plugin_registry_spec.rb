require "rails_helper"

RSpec.describe PluginRegistry do
  before(:each) do
    PluginRegistry.reload!
  end

  describe ".all" do
    it "returns an array of plugin classes" do
      expect(PluginRegistry.all).to be_an(Array)
      expect(PluginRegistry.all).to all(be < BasePlugin)
    end

    it "includes ExamplePlugin in the results" do
      expect(PluginRegistry.all).to include(ExamplePlugin)
    end

    it "does NOT include BasePlugin itself" do
      expect(PluginRegistry.all).not_to include(BasePlugin)
    end

    it "does NOT include PluginRegistry" do
      # PluginRegistry is not a plugin, so it should not be in the list
      expect(PluginRegistry.all).not_to include(PluginRegistry)
    end

    it "caches results (same object returned on subsequent calls)" do
      first_call = PluginRegistry.all
      second_call = PluginRegistry.all
      expect(first_call.object_id).to eq(second_call.object_id)
    end

    it "returns classes that respond to the plugin contract methods" do
      PluginRegistry.all.each do |plugin|
        expect(plugin).to respond_to(:name)
        expect(plugin).to respond_to(:version)
        expect(plugin).to respond_to(:description)
      end
    end
  end

  describe ".reload!" do
    it "clears the cache" do
      first_call = PluginRegistry.all
      PluginRegistry.reload!
      second_call = PluginRegistry.all

      # After reload, the object_id should be different (fresh array)
      expect(first_call.object_id).not_to eq(second_call.object_id)
    end

    it "returns fresh results after reload" do
      # First call populates cache
      initial_count = PluginRegistry.all.count

      # Reload and verify it still works
      PluginRegistry.reload!
      expect(PluginRegistry.all.count).to eq(initial_count)
    end
  end

  describe ".find(name)" do
    it "returns plugin class when found" do
      plugin = PluginRegistry.find("example")
      expect(plugin).to eq(ExamplePlugin)
    end

    it "returns nil when not found" do
      plugin = PluginRegistry.find("nonexistent")
      expect(plugin).to be_nil
    end

    it "works case-insensitively" do
      expect(PluginRegistry.find("Example")).to eq(ExamplePlugin)
      expect(PluginRegistry.find("EXAMPLE")).to eq(ExamplePlugin)
      expect(PluginRegistry.find("ExAmPlE")).to eq(ExamplePlugin)
    end

    it "returns nil for nil input" do
      expect(PluginRegistry.find(nil)).to be_nil
    end

    it "converts symbols to strings" do
      expect(PluginRegistry.find(:example)).to eq(ExamplePlugin)
    end
  end

  describe ".find!(name)" do
    it "returns plugin class when found" do
      plugin = PluginRegistry.find!("example")
      expect(plugin).to eq(ExamplePlugin)
    end

    it "raises PluginRegistry::NotFoundError when not found" do
      expect { PluginRegistry.find!("nonexistent") }.to raise_error(PluginRegistry::NotFoundError)
    end

    it "includes the requested name in the error message" do
      expect { PluginRegistry.find!("missing_plugin") }.to raise_error(
        PluginRegistry::NotFoundError,
        /missing_plugin/
      )
    end

    it "works case-insensitively" do
      expect(PluginRegistry.find!("EXAMPLE")).to eq(ExamplePlugin)
    end
  end

  describe ".registered_names" do
    it "returns an array of strings" do
      names = PluginRegistry.registered_names
      expect(names).to be_an(Array)
      expect(names).to all(be_a(String))
    end

    it "includes 'example' from ExamplePlugin" do
      expect(PluginRegistry.registered_names).to include("example")
    end

    it "has the same count as .all" do
      expect(PluginRegistry.registered_names.count).to eq(PluginRegistry.all.count)
    end
  end

  describe ".metadata" do
    it "returns an array of hashes" do
      metadata = PluginRegistry.metadata
      expect(metadata).to be_an(Array)
      expect(metadata).to all(be_a(Hash))
    end

    it "each hash has :name, :version, :description, :class keys" do
      PluginRegistry.metadata.each do |meta|
        expect(meta).to have_key(:name)
        expect(meta).to have_key(:version)
        expect(meta).to have_key(:description)
        expect(meta).to have_key(:class)
      end
    end

    it "contains accurate ExamplePlugin metadata" do
      example_metadata = PluginRegistry.metadata.find { |m| m[:name] == "example" }

      expect(example_metadata).not_to be_nil
      expect(example_metadata[:name]).to eq("example")
      expect(example_metadata[:version]).to eq("2.0.0")
      expect(example_metadata[:description]).to eq("Example bank integration plugin - demonstrates the plugin interface with mock bank data")
      expect(example_metadata[:class]).to eq(ExamplePlugin)
    end

    it "has the same count as .all" do
      expect(PluginRegistry.metadata.count).to eq(PluginRegistry.all.count)
    end
  end

  describe "NotFoundError" do
    it "is a subclass of StandardError" do
      expect(PluginRegistry::NotFoundError.superclass).to eq(StandardError)
    end
  end
end
