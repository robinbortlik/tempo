require "rails_helper"

RSpec.describe SyncHistory, type: :model do
  describe "validations" do
    it "requires plugin_name" do
      history = build(:sync_history, plugin_name: nil)
      expect(history).not_to be_valid
      expect(history.errors[:plugin_name]).to include("can't be blank")
    end
  end

  describe "enums" do
    it "defines status enum with correct values" do
      expect(described_class.statuses).to eq(
        "pending" => 0, "running" => 1, "completed" => 2, "failed" => 3
      )
    end
  end

  describe "scopes" do
    let!(:completed_sync) do
      create(:sync_history, plugin_name: "test", status: :completed, created_at: 1.hour.ago)
    end
    let!(:failed_sync) do
      create(:sync_history, plugin_name: "test", status: :failed, created_at: 2.hours.ago)
    end
    let!(:running_sync) do
      create(:sync_history, plugin_name: "test", status: :running, created_at: 30.minutes.ago)
    end
    let!(:pending_sync) do
      create(:sync_history, plugin_name: "other", status: :pending, created_at: 10.minutes.ago)
    end

    describe ".recent" do
      it "returns records ordered by created_at desc, limited to 10" do
        recent = described_class.recent
        expect(recent.first).to eq(pending_sync)
        expect(recent.count).to be <= 10
      end
    end

    describe ".for_plugin" do
      it "returns records for specific plugin" do
        expect(described_class.for_plugin("test").count).to eq(3)
        expect(described_class.for_plugin("other").count).to eq(1)
      end
    end

    describe ".successful" do
      it "returns only completed syncs" do
        expect(described_class.successful).to contain_exactly(completed_sync)
      end
    end

    describe ".unsuccessful" do
      it "returns only failed syncs" do
        expect(described_class.unsuccessful).to contain_exactly(failed_sync)
      end
    end

    describe ".in_progress" do
      it "returns pending and running syncs" do
        expect(described_class.in_progress).to contain_exactly(running_sync, pending_sync)
      end
    end

    describe ".today" do
      it "returns syncs from today" do
        expect(described_class.today.count).to eq(4) # All created within test
      end
    end

    describe ".this_week" do
      it "returns syncs from the last week" do
        expect(described_class.this_week.count).to eq(4)
      end
    end
  end

  describe "#duration" do
    it "returns nil when started_at is nil" do
      history = build(:sync_history, started_at: nil, completed_at: Time.current)
      expect(history.duration).to be_nil
    end

    it "returns nil when completed_at is nil" do
      history = build(:sync_history, started_at: Time.current, completed_at: nil)
      expect(history.duration).to be_nil
    end

    it "returns duration in seconds" do
      started = Time.current
      completed = started + 30.seconds
      history = build(:sync_history, started_at: started, completed_at: completed)
      expect(history.duration).to be_within(0.1).of(30)
    end
  end

  describe "#duration_formatted" do
    it "returns nil when duration is nil" do
      history = build(:sync_history, started_at: nil)
      expect(history.duration_formatted).to be_nil
    end

    it "formats seconds" do
      history = build(:sync_history, started_at: Time.current, completed_at: Time.current + 1.5.seconds)
      expect(history.duration_formatted).to eq("1.5s")
    end

    it "formats minutes and seconds" do
      history = build(:sync_history, started_at: Time.current, completed_at: Time.current + 135.seconds)
      expect(history.duration_formatted).to eq("2m 15s")
    end
  end

  describe "#in_progress?" do
    it "returns true for pending status" do
      expect(build(:sync_history, status: :pending).in_progress?).to be true
    end

    it "returns true for running status" do
      expect(build(:sync_history, status: :running).in_progress?).to be true
    end

    it "returns false for completed status" do
      expect(build(:sync_history, status: :completed).in_progress?).to be false
    end

    it "returns false for failed status" do
      expect(build(:sync_history, status: :failed).in_progress?).to be false
    end
  end

  describe "#successful?" do
    it "returns true for completed status" do
      expect(build(:sync_history, status: :completed).successful?).to be true
    end

    it "returns false for other statuses" do
      expect(build(:sync_history, status: :failed).successful?).to be false
      expect(build(:sync_history, status: :pending).successful?).to be false
    end
  end

  describe "#summary" do
    let(:history) do
      create(:sync_history,
             plugin_name: "test",
             status: :completed,
             started_at: Time.current - 5.seconds,
             completed_at: Time.current,
             records_processed: 100,
             records_created: 50,
             records_updated: 25)
    end

    it "returns hash with all expected keys" do
      summary = history.summary

      expect(summary[:id]).to eq(history.id)
      expect(summary[:plugin_name]).to eq("test")
      expect(summary[:status]).to eq("completed")
      expect(summary[:started_at]).to be_present
      expect(summary[:completed_at]).to be_present
      expect(summary[:duration]).to be_within(0.1).of(5)
      expect(summary[:duration_formatted]).to eq("5.0s")
      expect(summary[:records_processed]).to eq(100)
      expect(summary[:records_created]).to eq(50)
      expect(summary[:records_updated]).to eq(25)
      expect(summary[:error_message]).to be_nil
      expect(summary[:successful]).to be true
    end
  end

  describe ".stats_for_plugin" do
    before do
      3.times { create(:sync_history, plugin_name: "test", status: :completed, records_processed: 10) }
      2.times { create(:sync_history, plugin_name: "test", status: :failed, error_message: "Error") }
      create(:sync_history, plugin_name: "other", status: :completed)
    end

    let(:stats) { described_class.stats_for_plugin("test") }

    it "returns correct counts" do
      expect(stats[:total_syncs]).to eq(5)
      expect(stats[:successful_syncs]).to eq(3)
      expect(stats[:failed_syncs]).to eq(2)
    end

    it "calculates success rate" do
      expect(stats[:success_rate]).to eq(60.0)
    end

    it "returns last sync summary" do
      expect(stats[:last_sync]).to be_a(Hash)
      expect(stats[:last_sync][:plugin_name]).to eq("test")
    end

    it "returns total records processed" do
      expect(stats[:total_records_processed]).to eq(30)
    end
  end

  describe ".aggregate_stats" do
    before do
      3.times { create(:sync_history, plugin_name: "plugin1", status: :completed) }
      2.times { create(:sync_history, plugin_name: "plugin2", status: :failed) }
      create(:sync_history, plugin_name: "plugin3", status: :running)
    end

    let(:stats) { described_class.aggregate_stats }

    it "returns aggregate counts" do
      expect(stats[:total_syncs]).to eq(6)
      expect(stats[:successful_syncs]).to eq(3)
      expect(stats[:failed_syncs]).to eq(2)
      expect(stats[:in_progress]).to eq(1)
    end

    it "counts distinct plugins" do
      expect(stats[:plugins_synced]).to eq(3)
    end

    it "calculates overall success rate" do
      # 3 successful out of 5 completed/failed (excluding running)
      expect(stats[:success_rate]).to eq(60.0)
    end
  end
end
