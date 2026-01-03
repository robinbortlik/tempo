require 'rails_helper'

RSpec.describe PositionManager do
  let(:invoice) { create(:invoice) }
  let(:scope) { invoice.line_items }
  let(:manager) { described_class.new(scope) }

  describe "#next_position" do
    it "returns 1 when no items exist" do
      expect(manager.next_position).to eq(1)
    end

    it "returns max position + 1" do
      create(:invoice_line_item, invoice: invoice, position: 5)
      create(:invoice_line_item, invoice: invoice, position: 3)

      expect(manager.next_position).to eq(6)
    end
  end

  describe "#swap" do
    it "swaps positions of two items" do
      item1 = create(:invoice_line_item, invoice: invoice, position: 1)
      item2 = create(:invoice_line_item, invoice: invoice, position: 2)

      manager.swap(item1, item2)

      expect(item1.reload.position).to eq(2)
      expect(item2.reload.position).to eq(1)
    end

    it "handles non-adjacent positions" do
      item1 = create(:invoice_line_item, invoice: invoice, position: 1)
      item2 = create(:invoice_line_item, invoice: invoice, position: 5)

      manager.swap(item1, item2)

      expect(item1.reload.position).to eq(5)
      expect(item2.reload.position).to eq(1)
    end
  end

  describe "#move_up" do
    it "swaps with previous item" do
      item1 = create(:invoice_line_item, invoice: invoice, position: 0)
      item2 = create(:invoice_line_item, invoice: invoice, position: 1)

      result = manager.move_up(item2)

      expect(result).to be true
      expect(item2.reload.position).to eq(0)
      expect(item1.reload.position).to eq(1)
    end

    it "returns false when item is at position 0" do
      item = create(:invoice_line_item, invoice: invoice, position: 0)

      result = manager.move_up(item)

      expect(result).to be false
      expect(item.reload.position).to eq(0)
    end

    it "returns false when no item exists at previous position" do
      item = create(:invoice_line_item, invoice: invoice, position: 5)

      result = manager.move_up(item)

      expect(result).to be false
    end
  end

  describe "#move_down" do
    it "swaps with next item" do
      item1 = create(:invoice_line_item, invoice: invoice, position: 0)
      item2 = create(:invoice_line_item, invoice: invoice, position: 1)

      result = manager.move_down(item1)

      expect(result).to be true
      expect(item1.reload.position).to eq(1)
      expect(item2.reload.position).to eq(0)
    end

    it "returns false when no item exists at next position" do
      item = create(:invoice_line_item, invoice: invoice, position: 0)

      result = manager.move_down(item)

      expect(result).to be false
    end
  end

  describe "#reorder" do
    let!(:item1) { create(:invoice_line_item, invoice: invoice, position: 0) }
    let!(:item2) { create(:invoice_line_item, invoice: invoice, position: 1) }

    it "moves up when direction is 'up'" do
      result = manager.reorder(item2, "up")

      expect(result).to be true
      expect(item2.reload.position).to eq(0)
    end

    it "moves down when direction is 'down'" do
      result = manager.reorder(item1, "down")

      expect(result).to be true
      expect(item1.reload.position).to eq(1)
    end

    it "accepts symbol direction" do
      result = manager.reorder(item2, :up)

      expect(result).to be true
      expect(item2.reload.position).to eq(0)
    end

    it "returns false for unknown direction" do
      result = manager.reorder(item1, "sideways")

      expect(result).to be false
    end
  end
end
