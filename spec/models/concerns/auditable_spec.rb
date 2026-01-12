require "rails_helper"

RSpec.describe Auditable, type: :model do
  # Use MoneyTransaction as test subject since it includes Auditable
  let(:transaction_attrs) do
    {
      source: "test_plugin",
      amount: 100.00,
      currency: "EUR",
      transacted_on: Date.current,
      transaction_type: :income
    }
  end

  before do
    # Ensure audit context is clean
    Current.audit_source = nil
    Current.audit_sync_history_id = nil
  end

  describe "after_create callback" do
    it "creates audit log entry for new record" do
      expect {
        MoneyTransaction.create!(transaction_attrs)
      }.to change(DataAuditLog, :count).by(1)
    end

    it "records create action" do
      transaction = MoneyTransaction.create!(transaction_attrs)

      log = DataAuditLog.last
      expect(log.auditable_type).to eq("MoneyTransaction")
      expect(log.auditable_id).to eq(transaction.id)
      expect(log.action).to eq("create_action")
    end

    it "records audit source from Current" do
      Current.audit_source = "fio_bank"

      MoneyTransaction.create!(transaction_attrs)

      log = DataAuditLog.last
      expect(log.source).to eq("fio_bank")
    end

    it "records sync_history_id from Current" do
      sync_history = create(:sync_history)
      Current.audit_sync_history_id = sync_history.id

      MoneyTransaction.create!(transaction_attrs)

      log = DataAuditLog.last
      expect(log.sync_history_id).to eq(sync_history.id)
    end
  end

  describe "after_update callback" do
    let!(:transaction) { MoneyTransaction.create!(transaction_attrs) }

    before do
      DataAuditLog.delete_all # Clear create log
    end

    it "creates audit log entry for updates" do
      expect {
        transaction.update!(amount: 200.00)
      }.to change(DataAuditLog, :count).by(1)
    end

    it "records update action" do
      transaction.update!(amount: 200.00)

      log = DataAuditLog.last
      expect(log.action).to eq("update_action")
    end

    it "records attribute changes" do
      transaction.update!(amount: 200.00, description: "Updated description")

      log = DataAuditLog.last
      # JSON serialization converts BigDecimal to string
      expect(log.changes_made["amount"]["from"].to_f).to eq(100.0)
      expect(log.changes_made["amount"]["to"].to_f).to eq(200.0)
      expect(log.changes_made["description"]).to be_present
    end

    it "excludes timestamp changes" do
      transaction.update!(amount: 200.00)

      log = DataAuditLog.last
      expect(log.changes_made.keys).not_to include("updated_at")
      expect(log.changes_made.keys).not_to include("created_at")
    end

    it "does not log when only timestamps change" do
      # Touch without attribute changes should not create audit entry
      # This is handled by the touch mechanism
      expect {
        transaction.touch
      }.not_to change { DataAuditLog.updates.count }
    end

    it "does not log when no relevant changes" do
      expect {
        transaction.save! # No changes
      }.not_to change(DataAuditLog, :count)
    end
  end

  describe "after_destroy callback" do
    let!(:transaction) { MoneyTransaction.create!(transaction_attrs) }

    before do
      DataAuditLog.delete_all # Clear create log
    end

    it "creates audit log entry for destroy" do
      expect {
        transaction.destroy!
      }.to change(DataAuditLog, :count).by(1)
    end

    it "records destroy action" do
      transaction.destroy!

      log = DataAuditLog.last
      expect(log.action).to eq("destroy_action")
    end

    it "records final state in changes" do
      transaction.destroy!

      log = DataAuditLog.last
      # JSON serialization converts BigDecimal to string
      expect(log.changes_made["final_state"]["amount"].to_f).to eq(100.0)
      expect(log.changes_made["final_state"]).to include("source" => "test_plugin")
    end
  end

  describe "#audit_history" do
    let!(:transaction) { MoneyTransaction.create!(transaction_attrs) }

    before do
      transaction.update!(amount: 200.00)
      transaction.update!(description: "New description")
    end

    it "returns all audit entries for the record" do
      history = transaction.audit_history

      expect(history.count).to eq(3) # create + 2 updates
    end

    it "returns most recent first" do
      history = transaction.audit_history

      expect(history.first[:action]).to eq("update")
      expect(history.last[:action]).to eq("create")
    end
  end

  describe "#last_audit_entry" do
    let!(:transaction) { MoneyTransaction.create!(transaction_attrs) }

    it "returns most recent audit entry" do
      entry = transaction.last_audit_entry

      expect(entry).to be_a(DataAuditLog)
      expect(entry.action).to eq("create_action")
    end

    it "returns nil when no entries exist" do
      DataAuditLog.delete_all
      expect(transaction.last_audit_entry).to be_nil
    end
  end

  describe "#created_by_plugin?" do
    context "when created by a plugin" do
      before { Current.audit_source = "fio_bank" }

      it "returns true" do
        transaction = MoneyTransaction.create!(transaction_attrs)
        expect(transaction.created_by_plugin?).to be true
      end
    end

    context "when created by user" do
      before { Current.audit_source = "user" }

      it "returns false" do
        transaction = MoneyTransaction.create!(transaction_attrs)
        expect(transaction.created_by_plugin?).to be false
      end
    end

    context "when created without source" do
      before { Current.audit_source = nil }

      it "returns false" do
        transaction = MoneyTransaction.create!(transaction_attrs)
        expect(transaction.created_by_plugin?).to be false
      end
    end
  end

  describe "#created_by" do
    it "returns the source of the create entry" do
      Current.audit_source = "fio_bank"
      transaction = MoneyTransaction.create!(transaction_attrs)

      expect(transaction.created_by).to eq("fio_bank")
    end
  end

  describe "error handling" do
    it "does not break main operation if audit logging fails" do
      # Simulate audit log failure
      allow(DataAuditLog).to receive(:create!).and_raise(StandardError, "DB error")
      allow(Rails.logger).to receive(:error)

      # Main operation should still succeed
      expect {
        MoneyTransaction.create!(transaction_attrs)
      }.not_to raise_error
    end
  end
end
