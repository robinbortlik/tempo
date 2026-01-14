require "rails_helper"

RSpec.describe SyncHistorySerializer do
  let(:sync_history) do
    create(:sync_history,
           plugin_name: "example",
           status: :completed,
           started_at: 2.minutes.ago,
           completed_at: 1.minute.ago,
           records_processed: 10,
           records_created: 5,
           records_updated: 3)
  end

  describe "default serializer" do
    it "serializes sync history attributes" do
      result = described_class.new(sync_history).serializable_hash

      expect(result["id"]).to eq(sync_history.id)
      expect(result["plugin_name"]).to eq("example")
      expect(result["status"]).to eq("completed")
      expect(result["records_processed"]).to eq(10)
      expect(result["records_created"]).to eq(5)
      expect(result["records_updated"]).to eq(3)
      expect(result["error_message"]).to be_nil
    end

    it "formats started_at as ISO8601" do
      result = described_class.new(sync_history).serializable_hash

      expect(result["started_at"]).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it "formats completed_at as ISO8601" do
      result = described_class.new(sync_history).serializable_hash

      expect(result["completed_at"]).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it "includes duration" do
      result = described_class.new(sync_history).serializable_hash

      expect(result["duration"]).to be_present
      expect(result["duration"]).to be_a(Numeric)
    end

    it "includes duration_formatted" do
      result = described_class.new(sync_history).serializable_hash

      expect(result["duration_formatted"]).to be_present
      expect(result["duration_formatted"]).to match(/s$/)
    end

    it "includes successful flag" do
      result = described_class.new(sync_history).serializable_hash

      expect(result["successful"]).to be true
    end

    it "handles nil timestamps" do
      sync_history = create(:sync_history, plugin_name: "example", started_at: nil, completed_at: nil)

      result = described_class.new(sync_history).serializable_hash

      expect(result["started_at"]).to be_nil
      expect(result["completed_at"]).to be_nil
      expect(result["duration"]).to be_nil
      expect(result["duration_formatted"]).to be_nil
    end
  end

  describe SyncHistorySerializer::List do
    it "serializes sync history for list view" do
      result = described_class.new([ sync_history ]).serializable_hash

      history = result.first
      expect(history["id"]).to eq(sync_history.id)
      expect(history["status"]).to eq("completed")
      expect(history["records_processed"]).to eq(10)
      expect(history["records_created"]).to eq(5)
      expect(history["records_updated"]).to eq(3)
      expect(history["successful"]).to be true
      expect(history["duration_formatted"]).to be_present
    end

    it "excludes plugin_name for list view" do
      result = described_class.new([ sync_history ]).serializable_hash

      history = result.first
      expect(history).not_to have_key("plugin_name")
    end

    it "excludes full duration for list view" do
      result = described_class.new([ sync_history ]).serializable_hash

      history = result.first
      expect(history).not_to have_key("duration")
    end

    it "serializes collection of sync histories" do
      sync1 = create(:sync_history, plugin_name: "example", status: :completed)
      sync2 = create(:sync_history, plugin_name: "example", status: :failed, error_message: "Connection timeout")

      result = described_class.new([ sync1, sync2 ]).serializable_hash

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first["status"]).to eq("completed")
      expect(result.second["status"]).to eq("failed")
      expect(result.second["error_message"]).to eq("Connection timeout")
    end
  end

  describe SyncHistorySerializer::Detail do
    before do
      create(:data_audit_log,
             sync_history: sync_history,
             source: "example",
             action: :create_action,
             auditable_type: "MoneyTransaction",
             auditable_id: 1)
      create(:data_audit_log,
             sync_history: sync_history,
             source: "example",
             action: :update_action,
             auditable_type: "MoneyTransaction",
             auditable_id: 2,
             changes_made: { "amount" => { "from" => 100, "to" => 200 } })
    end

    it "serializes sync history with audit entries" do
      result = described_class.new(sync_history).serializable_hash

      expect(result["id"]).to eq(sync_history.id)
      expect(result["plugin_name"]).to eq("example")
      expect(result["audit_entries"]).to be_an(Array)
      expect(result["audit_entries"].length).to eq(2)
    end

    it "includes all audit entry details" do
      result = described_class.new(sync_history).serializable_hash

      entry = result["audit_entries"].find { |e| e[:action] == "update" }
      expect(entry[:auditable_type]).to eq("MoneyTransaction")
      expect(entry[:auditable_id]).to eq(2)
      expect(entry[:changes_made]).to eq({ "amount" => { "from" => 100, "to" => 200 } })
    end

    it "returns empty array when no audit entries" do
      sync = create(:sync_history, plugin_name: "example", status: :completed)

      result = described_class.new(sync).serializable_hash

      expect(result["audit_entries"]).to eq([])
    end

    it "includes duration for detail view" do
      result = described_class.new(sync_history).serializable_hash

      expect(result["duration"]).to be_present
      expect(result["duration_formatted"]).to be_present
    end

    it "includes successful flag" do
      result = described_class.new(sync_history).serializable_hash

      expect(result["successful"]).to be true
    end

    it "shows failed status correctly" do
      failed_sync = create(:sync_history,
                          plugin_name: "example",
                          status: :failed,
                          error_message: "API timeout")

      result = described_class.new(failed_sync).serializable_hash

      expect(result["status"]).to eq("failed")
      expect(result["error_message"]).to eq("API timeout")
      expect(result["successful"]).to be false
    end
  end
end
