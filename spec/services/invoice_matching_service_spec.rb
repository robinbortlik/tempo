require "rails_helper"

RSpec.describe InvoiceMatchingService do
  describe ".match_all" do
    let!(:client) { create(:client) }

    context "with matching invoice and transaction" do
      let!(:invoice) { create(:invoice, :final, client: client, number: "2026-001", total_amount: 1000.00) }
      let!(:transaction) do
        create(:money_transaction,
               source: "fio_bank",
               transaction_type: :income,
               reference: "2026-001",
               amount: 1000.00,
               transacted_on: Date.current)
      end

      it "matches invoice to transaction" do
        expect { described_class.match_all }.to change { invoice.reload.status }.from("final").to("paid")
      end

      it "sets paid_at from transaction date" do
        described_class.match_all

        expect(invoice.reload.paid_at).to eq(Date.current)
      end

      it "links transaction to invoice" do
        described_class.match_all

        expect(transaction.reload.invoice_id).to eq(invoice.id)
      end

      it "returns count of matched invoices" do
        expect(described_class.match_all).to eq(1)
      end
    end

    context "with multiple payable invoices" do
      let!(:invoice1) { create(:invoice, :final, client: client, number: "2026-001", total_amount: 1000.00) }
      let!(:invoice2) { create(:invoice, :final, client: client, number: "2026-002", total_amount: 500.00) }
      let!(:transaction1) do
        create(:money_transaction, source: "fio_bank", transaction_type: :income,
               reference: "2026-001", amount: 1000.00, transacted_on: Date.current)
      end
      let!(:transaction2) do
        create(:money_transaction, source: "fio_bank", transaction_type: :income,
               reference: "2026-002", amount: 500.00, transacted_on: Date.yesterday)
      end

      it "matches all invoices with corresponding transactions" do
        expect(described_class.match_all).to eq(2)

        expect(invoice1.reload.status).to eq("paid")
        expect(invoice2.reload.status).to eq("paid")
      end
    end

    context "with amount mismatch" do
      let!(:invoice) { create(:invoice, :final, client: client, number: "2026-003", total_amount: 999.00) }
      let!(:transaction) do
        create(:money_transaction, source: "fio_bank", transaction_type: :income,
               reference: "2026-003", amount: 1000.00)
      end

      it "does not match when amount differs" do
        expect(described_class.match_all).to eq(0)

        expect(invoice.reload.status).to eq("final")
        expect(transaction.reload.invoice_id).to be_nil
      end
    end

    context "with draft invoice" do
      let!(:invoice) { create(:invoice, :draft, client: client, number: "2026-004", total_amount: 200.00) }
      let!(:transaction) do
        create(:money_transaction, source: "fio_bank", transaction_type: :income,
               reference: "2026-004", amount: 200.00)
      end

      it "does not match draft invoices" do
        expect(described_class.match_all).to eq(0)

        expect(invoice.reload.status).to eq("draft")
      end
    end

    context "with already matched transaction" do
      let!(:existing_invoice) { create(:invoice, :paid, client: client, number: "2026-005", total_amount: 100.00) }
      let!(:new_invoice) { create(:invoice, :final, client: client, number: "2026-006", total_amount: 100.00) }
      let!(:matched_transaction) do
        create(:money_transaction, source: "fio_bank", transaction_type: :income,
               reference: "2026-006", amount: 100.00, invoice: existing_invoice)
      end

      it "skips already matched transactions" do
        expect(described_class.match_all).to eq(0)

        expect(new_invoice.reload.status).to eq("final")
      end
    end

    context "with expense transaction" do
      let!(:invoice) { create(:invoice, :final, client: client, number: "2026-007", total_amount: 300.00) }
      let!(:transaction) do
        create(:money_transaction, source: "fio_bank", transaction_type: :expense,
               reference: "2026-007", amount: 300.00)
      end

      it "ignores expense transactions" do
        expect(described_class.match_all).to eq(0)

        expect(invoice.reload.status).to eq("final")
      end
    end

    context "with no transactions" do
      let!(:invoice) { create(:invoice, :final, client: client, number: "2026-008", total_amount: 400.00) }

      it "returns zero when no matching transactions exist" do
        expect(described_class.match_all).to eq(0)
      end
    end
  end
end
