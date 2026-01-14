require "rails_helper"

RSpec.describe DataAuditLog, type: :model do
  describe "validations" do
    it "requires auditable_type" do
      log = build(:data_audit_log, auditable_type: nil)
      expect(log).not_to be_valid
      expect(log.errors[:auditable_type]).to include("can't be blank")
    end

    it "requires auditable_id" do
      log = build(:data_audit_log, auditable_id: nil)
      expect(log).not_to be_valid
      expect(log.errors[:auditable_id]).to include("can't be blank")
    end

    it "requires action" do
      log = build(:data_audit_log, action: nil)
      expect(log).not_to be_valid
      expect(log.errors[:action]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to sync_history optionally" do
      log = create(:data_audit_log, sync_history: nil)
      expect(log).to be_valid

      sync_history = create(:sync_history)
      log_with_history = create(:data_audit_log, sync_history: sync_history)
      expect(log_with_history.sync_history).to eq(sync_history)
    end
  end

  describe "enums" do
    it "defines action enum" do
      expect(described_class.actions).to include(
        "create_action" => "create",
        "update_action" => "update",
        "destroy_action" => "destroy"
      )
    end
  end

  describe "scopes" do
    let!(:create_log) { create(:data_audit_log, action: :create_action, source: "plugin1") }
    let!(:update_log) { create(:data_audit_log, action: :update_action, source: "plugin2") }
    let!(:destroy_log) { create(:data_audit_log, action: :destroy_action, source: "user") }

    describe ".for_source" do
      it "returns logs for specific source" do
        expect(described_class.for_source("plugin1")).to contain_exactly(create_log)
      end
    end

    describe ".from_plugins" do
      it "excludes user and nil sources" do
        expect(described_class.from_plugins).to contain_exactly(create_log, update_log)
      end
    end

    describe ".from_user" do
      it "returns user changes only" do
        expect(described_class.from_user).to contain_exactly(destroy_log)
      end
    end

    describe ".creates" do
      it "returns create actions only" do
        expect(described_class.creates).to contain_exactly(create_log)
      end
    end

    describe ".updates" do
      it "returns update actions only" do
        expect(described_class.updates).to contain_exactly(update_log)
      end
    end

    describe ".destroys" do
      it "returns destroy actions only" do
        expect(described_class.destroys).to contain_exactly(destroy_log)
      end
    end
  end

  describe "#description" do
    it "describes create action" do
      log = build(:data_audit_log, action: :create_action, auditable_type: "MoneyTransaction", auditable_id: 123)
      expect(log.description).to eq("Created MoneyTransaction #123")
    end

    it "describes update action with changed attributes" do
      log = build(:data_audit_log,
                  action: :update_action,
                  auditable_type: "MoneyTransaction",
                  auditable_id: 123,
                  changes_made: { "amount" => { from: 100, to: 200 }, "description" => { from: "old", to: "new" } })
      expect(log.description).to include("Updated MoneyTransaction #123")
      expect(log.description).to include("amount")
      expect(log.description).to include("description")
    end

    it "describes destroy action" do
      log = build(:data_audit_log, action: :destroy_action, auditable_type: "MoneyTransaction", auditable_id: 123)
      expect(log.description).to eq("Destroyed MoneyTransaction #123")
    end
  end

  describe "#summary" do
    let(:log) do
      create(:data_audit_log,
             action: :create_action,
             auditable_type: "MoneyTransaction",
             auditable_id: 123,
             source: "example",
             changes_made: { test: "data" })
    end

    it "returns hash with all expected keys" do
      summary = log.summary

      expect(summary[:id]).to eq(log.id)
      expect(summary[:auditable_type]).to eq("MoneyTransaction")
      expect(summary[:auditable_id]).to eq(123)
      expect(summary[:action]).to eq("create")
      expect(summary[:source]).to eq("example")
      expect(summary[:changes_made]).to eq({ "test" => "data" })
      expect(summary[:description]).to include("Created")
      expect(summary[:created_at]).to be_present
    end
  end

  describe ".stats_for_source" do
    before do
      3.times { |i| create(:data_audit_log, source: "plugin1", action: :create_action, auditable_id: i + 1) }
      2.times { create(:data_audit_log, source: "plugin1", action: :update_action, auditable_id: 1) }
      create(:data_audit_log, source: "plugin1", action: :destroy_action, auditable_id: 3)
      create(:data_audit_log, source: "plugin2", action: :create_action)
    end

    let(:stats) { described_class.stats_for_source("plugin1") }

    it "returns correct counts" do
      expect(stats[:total_changes]).to eq(6)
      expect(stats[:creates]).to eq(3)
      expect(stats[:updates]).to eq(2)
      expect(stats[:destroys]).to eq(1)
    end

    it "counts affected records" do
      expect(stats[:affected_records]).to eq(3)
    end

    it "returns affected types" do
      expect(stats[:affected_types]).to include("MoneyTransaction")
    end

    it "returns last change" do
      expect(stats[:last_change]).to be_a(Hash)
      expect(stats[:last_change][:source]).to eq("plugin1")
    end
  end

  describe ".history_for" do
    it "returns audit history for record" do
      # Create a MoneyTransaction manually without triggering Auditable callbacks
      # by directly inserting a record
      transaction = MoneyTransaction.new(
        source: "test_plugin",
        amount: 100.00,
        currency: "EUR",
        transacted_on: Date.current,
        transaction_type: :income
      )
      transaction.save(validate: false)

      # Clear any auto-generated logs and create specific test logs
      DataAuditLog.delete_all

      create(:data_audit_log, auditable: transaction, action: :create_action, created_at: 2.hours.ago)
      create(:data_audit_log, auditable: transaction, action: :update_action, created_at: 1.hour.ago)

      history = described_class.history_for(transaction)

      expect(history.count).to eq(2)
      expect(history.first[:action]).to eq("update") # Most recent first
      expect(history.last[:action]).to eq("create")
    end
  end

  describe ".recent_by_sync" do
    let(:sync1) { create(:sync_history, plugin_name: "plugin1") }
    let(:sync2) { create(:sync_history, plugin_name: "plugin2") }

    before do
      2.times { create(:data_audit_log, sync_history: sync1) }
      3.times { create(:data_audit_log, sync_history: sync2) }
      create(:data_audit_log, sync_history: nil) # No sync association
    end

    it "groups changes by sync operation" do
      result = described_class.recent_by_sync(limit: 10)

      expect(result.keys).to contain_exactly(sync1.id, sync2.id)
      expect(result[sync1.id].count).to eq(2)
      expect(result[sync2.id].count).to eq(3)
    end
  end
end
