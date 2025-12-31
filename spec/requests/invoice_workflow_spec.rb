require 'rails_helper'

RSpec.describe "Invoice Creation Workflow", type: :request do
  let(:client) { create(:client, hourly_rate: 100, currency: "EUR", payment_terms: "Net 30") }
  let(:project) { create(:project, client: client, hourly_rate: 100) }

  before { sign_in }

  describe "complete workflow: log work -> create invoice -> finalize" do
    it "handles mixed entry types through the complete invoice workflow" do
      # Create work entries (time and fixed)
      time_entry = create(:work_entry, :time_entry, project: project, date: Date.current, hours: 8, status: :unbilled)
      fixed_entry = create(:work_entry, :fixed_entry, project: project, date: Date.current, amount: 500, status: :unbilled)

      # Create draft invoice
      post invoices_path, params: {
        invoice: { client_id: client.id, period_start: 1.month.ago.to_date, period_end: Date.current }
      }

      invoice = Invoice.last
      expect(invoice.status).to eq("draft")
      expect(invoice.line_items.time_aggregate.count).to eq(1)
      expect(invoice.line_items.fixed.count).to eq(1)

      # Work entries are linked and marked invoiced
      expect(time_entry.reload.status).to eq("invoiced")
      expect(fixed_entry.reload.status).to eq("invoiced")

      # Finalize invoice
      post finalize_invoice_path(invoice)
      expect(invoice.reload.status).to eq("final")
    end

    it "unlinks work entries when removing line item from draft" do
      work_entry = create(:work_entry, :time_entry, project: project, date: Date.current, hours: 8, status: :unbilled)

      post invoices_path, params: {
        invoice: { client_id: client.id, period_start: 1.month.ago.to_date, period_end: Date.current }
      }

      invoice = Invoice.last
      line_item = invoice.line_items.first

      # Remove line item
      delete invoice_line_item_path(invoice, line_item)

      # Work entry should be unlinked and unbilled
      work_entry.reload
      expect(work_entry.status).to eq("unbilled")
      expect(work_entry.invoice_id).to be_nil
    end
  end
end
