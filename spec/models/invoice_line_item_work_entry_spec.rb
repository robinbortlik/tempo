require 'rails_helper'

RSpec.describe InvoiceLineItemWorkEntry, type: :model do
  describe "associations" do
    it "belongs to invoice_line_item" do
      association = described_class.reflect_on_association(:invoice_line_item)
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to work_entry" do
      association = described_class.reflect_on_association(:work_entry)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "uniqueness constraint" do
    it "prevents duplicate work entry links" do
      line_item = create(:invoice_line_item)
      work_entry = create(:work_entry)

      # First link should succeed
      create(:invoice_line_item_work_entry, invoice_line_item: line_item, work_entry: work_entry)

      # Second link should fail
      duplicate = build(:invoice_line_item_work_entry, invoice_line_item: line_item, work_entry: work_entry)
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
