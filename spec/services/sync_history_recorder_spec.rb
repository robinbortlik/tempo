require "rails_helper"

RSpec.describe SyncHistoryRecorder do
  let(:plugin_name) { "example" }
  let(:recorder) { described_class.new(plugin_name: plugin_name) }

  describe "#record_start" do
    it "creates a sync history with running status" do
      history = recorder.record_start

      expect(history).to be_persisted
      expect(history.plugin_name).to eq(plugin_name)
      expect(history.status).to eq("running")
      expect(history.started_at).to be_present
    end

    it "does not set completed_at" do
      history = recorder.record_start
      expect(history.completed_at).to be_nil
    end
  end

  describe "#record_success" do
    let!(:history) { recorder.record_start }

    it "updates status to completed" do
      recorder.record_success(history)

      history.reload
      expect(history.status).to eq("completed")
    end

    it "sets completed_at" do
      recorder.record_success(history)

      history.reload
      expect(history.completed_at).to be_present
    end

    it "records statistics" do
      recorder.record_success(history,
                              records_processed: 100,
                              records_created: 50,
                              records_updated: 30)

      history.reload
      expect(history.records_processed).to eq(100)
      expect(history.records_created).to eq(50)
      expect(history.records_updated).to eq(30)
    end

    it "defaults statistics to 0" do
      recorder.record_success(history)

      history.reload
      expect(history.records_processed).to eq(0)
      expect(history.records_created).to eq(0)
      expect(history.records_updated).to eq(0)
    end

    it "returns the updated history" do
      result = recorder.record_success(history)
      expect(result).to eq(history)
      expect(result.status).to eq("completed")
    end
  end

  describe "#record_failure" do
    let!(:history) { recorder.record_start }

    it "updates status to failed" do
      recorder.record_failure(history, error: "Connection timeout")

      history.reload
      expect(history.status).to eq("failed")
    end

    it "sets completed_at" do
      recorder.record_failure(history, error: "Error")

      history.reload
      expect(history.completed_at).to be_present
    end

    it "records error message" do
      recorder.record_failure(history, error: "API returned 500 error")

      history.reload
      expect(history.error_message).to eq("API returned 500 error")
    end

    it "returns the updated history" do
      result = recorder.record_failure(history, error: "Error")
      expect(result).to eq(history)
      expect(result.status).to eq("failed")
    end
  end

  describe "#last_sync" do
    before do
      create(:sync_history, plugin_name: plugin_name, created_at: 2.hours.ago)
      create(:sync_history, plugin_name: plugin_name, created_at: 1.hour.ago)
      create(:sync_history, plugin_name: "other", created_at: 30.minutes.ago)
    end

    it "returns most recent sync for the plugin" do
      last = recorder.last_sync
      expect(last.plugin_name).to eq(plugin_name)
      expect(last.created_at).to be > 1.5.hours.ago
    end

    it "returns nil when no syncs exist" do
      recorder = described_class.new(plugin_name: "nonexistent")
      expect(recorder.last_sync).to be_nil
    end
  end

  describe "#last_successful_sync" do
    before do
      create(:sync_history, plugin_name: plugin_name, status: :failed, created_at: 1.hour.ago)
      create(:sync_history, plugin_name: plugin_name, status: :completed, created_at: 2.hours.ago)
    end

    it "returns most recent successful sync" do
      last = recorder.last_successful_sync
      expect(last.status).to eq("completed")
    end
  end

  describe "#stats" do
    before do
      3.times { create(:sync_history, plugin_name: plugin_name, status: :completed) }
      create(:sync_history, plugin_name: plugin_name, status: :failed)
    end

    it "returns statistics for the plugin" do
      stats = recorder.stats

      expect(stats[:plugin_name]).to eq(plugin_name)
      expect(stats[:total_syncs]).to eq(4)
      expect(stats[:successful_syncs]).to eq(3)
      expect(stats[:failed_syncs]).to eq(1)
    end
  end

  describe ".cleanup_orphaned" do
    let!(:recent_running) { create(:sync_history, status: :running, started_at: 30.minutes.ago) }
    let!(:old_running) { create(:sync_history, status: :running, started_at: 2.hours.ago) }
    let!(:old_pending) { create(:sync_history, status: :pending, started_at: 3.hours.ago) }
    let!(:old_completed) { create(:sync_history, status: :completed, started_at: 2.hours.ago) }

    it "marks old in-progress syncs as failed" do
      count = described_class.cleanup_orphaned

      expect(count).to eq(2)

      old_running.reload
      expect(old_running.status).to eq("failed")
      expect(old_running.error_message).to include("timed out")
      expect(old_running.completed_at).to be_present

      old_pending.reload
      expect(old_pending.status).to eq("failed")
    end

    it "does not affect recent in-progress syncs" do
      described_class.cleanup_orphaned

      recent_running.reload
      expect(recent_running.status).to eq("running")
    end

    it "does not affect completed syncs" do
      described_class.cleanup_orphaned

      old_completed.reload
      expect(old_completed.status).to eq("completed")
    end
  end

  describe ".recent_by_plugin" do
    before do
      3.times { create(:sync_history, plugin_name: "plugin1") }
      2.times { create(:sync_history, plugin_name: "plugin2") }
    end

    it "returns hash of recent syncs by plugin" do
      result = described_class.recent_by_plugin(limit: 2)

      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly("plugin1", "plugin2")
      expect(result["plugin1"].count).to eq(2)
      expect(result["plugin2"].count).to eq(2)
    end

    it "returns summaries not full records" do
      result = described_class.recent_by_plugin

      expect(result["plugin1"].first).to be_a(Hash)
      expect(result["plugin1"].first).to include(:id, :plugin_name, :status)
    end
  end
end
