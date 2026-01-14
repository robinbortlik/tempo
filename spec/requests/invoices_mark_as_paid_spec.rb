require 'rails_helper'

RSpec.describe "POST /invoices/:id/mark_as_paid", type: :request do
  let(:client) { create(:client, hourly_rate: 100, currency: "EUR") }

  describe "when authenticated" do
    before { sign_in }

    context "when invoice is final" do
      it "marks invoice as paid with provided date" do
        invoice = create(:invoice, :final, client: client)
        paid_date = "2025-01-10"

        post mark_as_paid_invoice_path(invoice), params: { paid_at: paid_date }

        invoice.reload
        expect(invoice.status).to eq("paid")
        expect(invoice.paid_at.to_date).to eq(Date.parse(paid_date))
      end

      it "redirects to invoice show with success notice" do
        invoice = create(:invoice, :final, client: client)

        post mark_as_paid_invoice_path(invoice), params: { paid_at: Date.current.to_s }

        expect(response).to redirect_to(invoice_path(invoice))
        follow_redirect!
        expect(flash[:notice]).to eq("Invoice marked as paid.")
      end

      it "defaults to current date when paid_at not provided" do
        invoice = create(:invoice, :final, client: client)

        post mark_as_paid_invoice_path(invoice)

        invoice.reload
        expect(invoice.status).to eq("paid")
        expect(invoice.paid_at.to_date).to eq(Date.current)
      end
    end

    context "when invoice is draft" do
      it "does not mark draft invoice as paid" do
        invoice = create(:invoice, :draft, client: client)

        post mark_as_paid_invoice_path(invoice), params: { paid_at: Date.current.to_s }

        invoice.reload
        expect(invoice.status).to eq("draft")
        expect(invoice.paid_at).to be_nil
      end

      it "redirects with error message" do
        invoice = create(:invoice, :draft, client: client)

        post mark_as_paid_invoice_path(invoice), params: { paid_at: Date.current.to_s }

        expect(response).to redirect_to(invoice_path(invoice))
        follow_redirect!
        expect(flash[:alert]).to eq("Only final invoices can be marked as paid.")
      end
    end

    context "when invoice is already paid" do
      it "does not change already paid invoice" do
        original_paid_at = 1.week.ago
        invoice = create(:invoice, :paid, client: client, paid_at: original_paid_at)

        post mark_as_paid_invoice_path(invoice), params: { paid_at: Date.current.to_s }

        invoice.reload
        expect(invoice.paid_at.to_date).to eq(original_paid_at.to_date)
      end

      it "redirects with error message" do
        invoice = create(:invoice, :paid, client: client)

        post mark_as_paid_invoice_path(invoice), params: { paid_at: Date.current.to_s }

        expect(response).to redirect_to(invoice_path(invoice))
        follow_redirect!
        expect(flash[:alert]).to eq("Only final invoices can be marked as paid.")
      end
    end
  end

  describe "when not authenticated" do
    it "redirects to login" do
      invoice = create(:invoice, :final, client: client)

      post mark_as_paid_invoice_path(invoice), params: { paid_at: Date.current.to_s }

      expect(response).to redirect_to(new_session_path)
    end
  end
end
