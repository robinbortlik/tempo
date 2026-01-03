require 'rails_helper'

RSpec.describe InvoiceLineItemSerializer do
  let(:invoice) { create(:invoice) }

  describe "time_aggregate line item" do
    let(:line_item) do
      create(:invoice_line_item, :time_aggregate,
             invoice: invoice,
             description: "Development work",
             quantity: 8.0,
             unit_price: 100.0,
             amount: 800.0,
             vat_rate: 21.0,
             position: 1)
    end

    it "serializes basic attributes" do
      result = described_class.new(line_item).serializable_hash

      expect(result["id"]).to eq(line_item.id)
      expect(result["line_type"]).to eq("time_aggregate")
      expect(result["description"]).to eq("Development work")
      expect(result["position"]).to eq(1)
    end

    it "converts numeric values to floats" do
      result = described_class.new(line_item).serializable_hash

      expect(result["quantity"]).to eq(8.0)
      expect(result["unit_price"]).to eq(100.0)
      expect(result["amount"]).to eq(800.0)
      expect(result["vat_rate"]).to eq(21.0)
    end

    it "calculates vat_amount" do
      result = described_class.new(line_item).serializable_hash

      expect(result["vat_amount"]).to be_a(Float)
    end
  end

  describe "fixed line item" do
    let(:line_item) do
      create(:invoice_line_item, :fixed,
             invoice: invoice,
             description: "Fixed deliverable",
             amount: 500.0,
             position: 2)
    end

    it "serializes fixed item attributes" do
      result = described_class.new(line_item).serializable_hash

      expect(result["line_type"]).to eq("fixed")
      expect(result["description"]).to eq("Fixed deliverable")
      expect(result["amount"]).to eq(500.0)
    end

    it "has nil quantity and unit_price" do
      result = described_class.new(line_item).serializable_hash

      expect(result["quantity"]).to be_nil
      expect(result["unit_price"]).to be_nil
    end
  end

  describe "work_entry_ids" do
    let(:project) { create(:project, client: invoice.client) }
    let(:entry1) { create(:work_entry, project: project) }
    let(:entry2) { create(:work_entry, project: project) }
    let(:line_item) { create(:invoice_line_item, invoice: invoice) }

    before do
      line_item.work_entries << entry1
      line_item.work_entries << entry2
    end

    it "includes associated work entry IDs" do
      result = described_class.new(line_item).serializable_hash

      expect(result["work_entry_ids"]).to contain_exactly(entry1.id, entry2.id)
    end
  end

  describe "collection serialization" do
    let(:item1) { create(:invoice_line_item, invoice: invoice, position: 1) }
    let(:item2) { create(:invoice_line_item, invoice: invoice, position: 2) }

    it "serializes array of line items" do
      result = described_class.new([ item1, item2 ]).serializable_hash

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end
  end
end
