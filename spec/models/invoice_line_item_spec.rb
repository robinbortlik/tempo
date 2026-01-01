require 'rails_helper'

RSpec.describe InvoiceLineItem, type: :model do
  describe "associations" do
    it "belongs to an invoice" do
      association = described_class.reflect_on_association(:invoice)
      expect(association.macro).to eq(:belongs_to)
    end

    it "has many work_entries through join table" do
      association = described_class.reflect_on_association(:work_entries)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:invoice_line_item_work_entries)
    end
  end

  describe "line_type enum" do
    it "has time_aggregate and fixed types" do
      expect(InvoiceLineItem.line_types).to eq({ "time_aggregate" => 0, "fixed" => 1 })
    end

    it "provides type checking methods" do
      time_item = build(:invoice_line_item, :time_aggregate)
      fixed_item = build(:invoice_line_item, :fixed)

      expect(time_item.time_aggregate?).to be true
      expect(time_item.fixed?).to be false

      expect(fixed_item.fixed?).to be true
      expect(fixed_item.time_aggregate?).to be false
    end
  end

  describe "validations" do
    it "requires description" do
      item = build(:invoice_line_item, description: nil)
      expect(item).not_to be_valid
      expect(item.errors[:description]).to include("can't be blank")
    end

    it "requires amount" do
      item = build(:invoice_line_item, amount: nil)
      expect(item).not_to be_valid
      expect(item.errors[:amount]).to include("can't be blank")
    end

    it "requires position" do
      item = build(:invoice_line_item, position: nil)
      expect(item).not_to be_valid
      expect(item.errors[:position]).to include("can't be blank")
    end
  end

  describe "default scope" do
    let(:invoice) { create(:invoice) }

    it "orders by position" do
      item3 = create(:invoice_line_item, invoice: invoice, position: 3)
      item1 = create(:invoice_line_item, invoice: invoice, position: 1)
      item2 = create(:invoice_line_item, invoice: invoice, position: 2)

      expect(invoice.line_items.to_a).to eq([ item1, item2, item3 ])
    end
  end

  describe "vat_rate column" do
    it "accepts and persists vat_rate decimal value" do
      item = create(:invoice_line_item, vat_rate: 21.00)
      expect(item.reload.vat_rate).to eq(21.00)
    end

    it "defaults to 0 for new records" do
      item = create(:invoice_line_item)
      expect(item.vat_rate).to eq(0)
    end
  end

  describe "vat_rate validation" do
    it "rejects vat_rate greater than 100" do
      item = build(:invoice_line_item, vat_rate: 101)
      expect(item).not_to be_valid
      expect(item.errors[:vat_rate]).to include("must be less than or equal to 100")
    end

    it "rejects negative vat_rate" do
      item = build(:invoice_line_item, vat_rate: -1)
      expect(item).not_to be_valid
      expect(item.errors[:vat_rate]).to include("must be greater than or equal to 0")
    end
  end

  describe "#vat_amount" do
    it "calculates VAT correctly (100.00 amount with 21% rate = 21.00)" do
      item = build(:invoice_line_item, amount: 100.00, vat_rate: 21.00)
      expect(item.vat_amount).to eq(21.00)
    end

    it "rounds to 2 decimal places" do
      item = build(:invoice_line_item, amount: 33.33, vat_rate: 21.00)
      # 33.33 * 0.21 = 6.9993, should round to 7.00
      expect(item.vat_amount).to eq(7.00)
    end

    it "returns 0 for 0% VAT rate" do
      item = build(:invoice_line_item, amount: 100.00, vat_rate: 0)
      expect(item.vat_amount).to eq(0)
    end
  end
end
