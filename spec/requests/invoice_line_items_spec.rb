require 'rails_helper'

RSpec.describe InvoiceLineItemsController, type: :request do
  let(:client) { create(:client, hourly_rate: 100, currency: "EUR") }
  let(:project) { create(:project, client: client, hourly_rate: 100) }
  let(:invoice) { create(:invoice, client: client, status: :draft) }

  before { sign_in }

  describe "line item management" do
    it "adds manual line items and recalculates totals" do
      create(:invoice_line_item, invoice: invoice, amount: 1000, position: 0)
      invoice.calculate_totals!
      initial_total = invoice.reload.total_amount

      post invoice_line_items_path(invoice), params: {
        line_item: { description: "Manual item", amount: 250, line_type: :fixed }
      }

      item = invoice.line_items.last
      expect(item.description).to eq("Manual item")
      expect(invoice.reload.total_amount).to be > initial_total
    end

    it "removes line items and unlinks work entries back to unbilled" do
      work_entry = create(:work_entry, project: project, status: :invoiced, invoice: invoice)
      line_item = create(:invoice_line_item, invoice: invoice)
      create(:invoice_line_item_work_entry, invoice_line_item: line_item, work_entry: work_entry)

      expect { delete invoice_line_item_path(invoice, line_item) }.to change(InvoiceLineItem, :count).by(-1)

      work_entry.reload
      expect(work_entry.status).to eq("unbilled")
      expect(work_entry.invoice_id).to be_nil
    end
  end

  describe "reorder" do
    let!(:item1) { create(:invoice_line_item, invoice: invoice, description: "First", position: 0) }
    let!(:item2) { create(:invoice_line_item, invoice: invoice, description: "Second", position: 1) }

    it "swaps positions when moving item down" do
      patch reorder_invoice_line_item_path(invoice, item1), params: { direction: "down" }

      expect(response).to redirect_to(invoice_path(invoice))
      expect(item1.reload.position).to eq(1)
      expect(item2.reload.position).to eq(0)
    end

    it "swaps positions when moving item up" do
      patch reorder_invoice_line_item_path(invoice, item2), params: { direction: "up" }

      expect(response).to redirect_to(invoice_path(invoice))
      expect(item1.reload.position).to eq(1)
      expect(item2.reload.position).to eq(0)
    end

    it "handles edge case when item is already at top" do
      patch reorder_invoice_line_item_path(invoice, item1), params: { direction: "up" }

      expect(response).to redirect_to(invoice_path(invoice))
      # Positions should remain unchanged
      expect(item1.reload.position).to eq(0)
      expect(item2.reload.position).to eq(1)
    end

    it "handles edge case when item is already at bottom" do
      patch reorder_invoice_line_item_path(invoice, item2), params: { direction: "down" }

      expect(response).to redirect_to(invoice_path(invoice))
      # Positions should remain unchanged
      expect(item1.reload.position).to eq(0)
      expect(item2.reload.position).to eq(1)
    end
  end
end
