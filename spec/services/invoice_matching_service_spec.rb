require "rails_helper"

RSpec.describe InvoiceMatchingService do
  describe ".match_all" do
    let!(:client) { create(:client) }
    let!(:invoice) { create(:invoice, :final, client: client, number: "2026-001", total_amount: 1000.00) }
    let!(:transaction) do
      create(:money_transaction,
             source: "fio_bank",
             transaction_type: :income,
             reference: "2026-001",
             amount: 1000.00,
             transacted_on: Date.current)
    end

    it "matches unmatched income transactions to invoices" do
      described_class.match_all

      invoice.reload
      transaction.reload

      expect(invoice.status).to eq("paid")
      expect(invoice.paid_at).to eq(Date.current)
      expect(transaction.invoice_id).to eq(invoice.id)
    end
  end

  describe "#match" do
    let!(:client) { create(:client) }

    context "with matching invoice" do
      let!(:invoice) { create(:invoice, :final, client: client, number: "2026-002", total_amount: 500.00) }
      let(:transaction) do
        create(:money_transaction,
               source: "fio_bank",
               transaction_type: :income,
               reference: "2026-002",
               amount: 500.00,
               transacted_on: Date.yesterday)
      end

      it "marks invoice as paid with correct paid_at date" do
        result = described_class.new(transaction).match

        expect(result[:success]).to be true
        expect(invoice.reload.status).to eq("paid")
        expect(invoice.paid_at).to eq(Date.yesterday)
      end

      it "links transaction to invoice" do
        described_class.new(transaction).match

        expect(transaction.reload.invoice_id).to eq(invoice.id)
      end
    end

    context "with already matched transaction" do
      let!(:existing_invoice) { create(:invoice, :paid, client: client) }
      let(:transaction) do
        create(:money_transaction,
               source: "fio_bank",
               transaction_type: :income,
               reference: "2026-003",
               amount: 100.00,
               invoice: existing_invoice)
      end

      it "returns error for already matched transaction" do
        result = described_class.new(transaction).match

        expect(result[:success]).to be false
        expect(result[:error]).to include("already matched")
      end
    end

    context "with no matching invoice (different amount)" do
      let!(:invoice) { create(:invoice, :final, client: client, number: "2026-004", total_amount: 999.00) }
      let(:transaction) do
        create(:money_transaction,
               source: "fio_bank",
               transaction_type: :income,
               reference: "2026-004",
               amount: 1000.00)
      end

      it "does not match when amount differs" do
        result = described_class.new(transaction).match

        expect(result[:success]).to be false
        expect(result[:error]).to include("No matching invoice")
        expect(invoice.reload.status).to eq("final")
      end
    end

    context "with draft invoice (not payable)" do
      let!(:invoice) { create(:invoice, :draft, client: client, number: "2026-005", total_amount: 200.00) }
      let(:transaction) do
        create(:money_transaction,
               source: "fio_bank",
               transaction_type: :income,
               reference: "2026-005",
               amount: 200.00)
      end

      it "does not match draft invoices" do
        result = described_class.new(transaction).match

        expect(result[:success]).to be false
        expect(invoice.reload.status).to eq("draft")
      end
    end

    context "with expense transaction" do
      let(:transaction) do
        create(:money_transaction,
               source: "fio_bank",
               transaction_type: :expense,
               reference: "2026-006",
               amount: 100.00)
      end

      it "does not match expense transactions" do
        result = described_class.new(transaction).match

        expect(result[:success]).to be false
        expect(result[:error]).to include("Not an income transaction")
      end
    end
  end
end
