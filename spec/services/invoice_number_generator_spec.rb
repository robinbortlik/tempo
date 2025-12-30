require 'rails_helper'

RSpec.describe InvoiceNumberGenerator do
  describe ".generate" do
    it "delegates to instance method" do
      allow_any_instance_of(InvoiceNumberGenerator).to receive(:generate).and_return("2024-001")
      expect(InvoiceNumberGenerator.generate).to eq("2024-001")
    end

    it "accepts year parameter" do
      result = InvoiceNumberGenerator.generate(year: 2023)
      expect(result).to start_with("2023-")
    end
  end

  describe "#generate" do
    context "when no invoices exist" do
      it "returns first invoice number for current year" do
        generator = InvoiceNumberGenerator.new
        expect(generator.generate).to eq("#{Date.current.year}-001")
      end

      it "uses the specified year" do
        generator = InvoiceNumberGenerator.new(year: 2023)
        expect(generator.generate).to eq("2023-001")
      end
    end

    context "when invoices exist for the year" do
      before do
        create(:invoice, number: "2024-001")
        create(:invoice, number: "2024-002")
      end

      it "returns the next sequential number" do
        generator = InvoiceNumberGenerator.new(year: 2024)
        expect(generator.generate).to eq("2024-003")
      end
    end

    context "when invoices exist for a different year" do
      before do
        create(:invoice, number: "2023-050")
      end

      it "starts from 001 for the new year" do
        generator = InvoiceNumberGenerator.new(year: 2024)
        expect(generator.generate).to eq("2024-001")
      end
    end

    context "with non-sequential invoice numbers" do
      before do
        create(:invoice, number: "2024-001")
        create(:invoice, number: "2024-010")
        create(:invoice, number: "2024-005")
      end

      it "uses the highest number as base" do
        generator = InvoiceNumberGenerator.new(year: 2024)
        expect(generator.generate).to eq("2024-011")
      end
    end

    context "with large sequence numbers" do
      before do
        create(:invoice, number: "2024-999")
      end

      it "handles numbers beyond 999" do
        generator = InvoiceNumberGenerator.new(year: 2024)
        expect(generator.generate).to eq("2024-1000")
      end
    end

    context "when current year is used by default" do
      it "uses the current year" do
        generator = InvoiceNumberGenerator.new
        expect(generator.generate).to start_with("#{Date.current.year}-")
      end
    end
  end

  describe "number format" do
    it "pads single digit numbers with zeros" do
      generator = InvoiceNumberGenerator.new(year: 2024)
      expect(generator.generate).to eq("2024-001")
    end

    it "pads double digit numbers with one zero" do
      9.times { |i| create(:invoice, number: "2024-#{(i + 1).to_s.rjust(3, '0')}") }
      generator = InvoiceNumberGenerator.new(year: 2024)
      expect(generator.generate).to eq("2024-010")
    end

    it "does not pad triple digit numbers" do
      create(:invoice, number: "2024-099")
      generator = InvoiceNumberGenerator.new(year: 2024)
      expect(generator.generate).to eq("2024-100")
    end
  end
end
