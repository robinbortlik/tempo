require "rails_helper"

RSpec.describe Current do
  after do
    # Clean up thread-local state
    described_class.reset
  end

  describe "audit attributes" do
    it "stores audit_source" do
      described_class.audit_source = "test_plugin"
      expect(described_class.audit_source).to eq("test_plugin")
    end

    it "stores audit_sync_history_id" do
      described_class.audit_sync_history_id = 123
      expect(described_class.audit_sync_history_id).to eq(123)
    end
  end

  describe ".with_audit_context" do
    it "sets audit context within block" do
      described_class.with_audit_context(source: "plugin_name", sync_history_id: 456) do
        expect(described_class.audit_source).to eq("plugin_name")
        expect(described_class.audit_sync_history_id).to eq(456)
      end
    end

    it "restores previous context after block" do
      described_class.audit_source = "original"
      described_class.audit_sync_history_id = 100

      described_class.with_audit_context(source: "temporary", sync_history_id: 999) do
        # Inside block
      end

      expect(described_class.audit_source).to eq("original")
      expect(described_class.audit_sync_history_id).to eq(100)
    end

    it "restores context even if block raises" do
      described_class.audit_source = "original"

      expect {
        described_class.with_audit_context(source: "temporary") do
          raise "test error"
        end
      }.to raise_error("test error")

      expect(described_class.audit_source).to eq("original")
    end

    it "handles nested contexts" do
      described_class.with_audit_context(source: "outer", sync_history_id: 1) do
        expect(described_class.audit_source).to eq("outer")

        described_class.with_audit_context(source: "inner", sync_history_id: 2) do
          expect(described_class.audit_source).to eq("inner")
          expect(described_class.audit_sync_history_id).to eq(2)
        end

        expect(described_class.audit_source).to eq("outer")
        expect(described_class.audit_sync_history_id).to eq(1)
      end
    end
  end
end
