require 'rails_helper'

RSpec.describe InvoicePdfService do
  let(:client) { create(:client) }
  let(:invoice) { create(:invoice, client: client, number: "2024-001") }
  let(:controller) { ApplicationController.new }

  before do
    # Stub controller's render_to_string
    allow(controller).to receive(:render_to_string).and_return("<html><body>Invoice</body></html>")
  end

  describe "#generate" do
    it "generates a PDF" do
      service = described_class.new(invoice: invoice, controller: controller)

      # Stub Grover to avoid actual PDF generation in tests
      grover_instance = instance_double(Grover)
      allow(Grover).to receive(:new).and_return(grover_instance)
      allow(grover_instance).to receive(:to_pdf).and_return("%PDF-1.4 fake pdf content")

      result = service.generate

      expect(result).to start_with("%PDF")
    end

    it "passes rendered HTML to Grover with A4 format" do
      service = described_class.new(invoice: invoice, controller: controller)

      expect(Grover).to receive(:new).with(
        anything,
        format: "A4"
      ).and_return(instance_double(Grover, to_pdf: ""))

      service.generate
    end

    it "renders invoice PDF template" do
      service = described_class.new(invoice: invoice, controller: controller)

      expect(controller).to receive(:render_to_string).with(
        hash_including(template: "invoices/pdf", layout: false)
      )

      allow(Grover).to receive(:new).and_return(instance_double(Grover, to_pdf: ""))
      service.generate
    end
  end

  describe "#filename" do
    it "returns filename based on invoice number" do
      service = described_class.new(invoice: invoice, controller: controller)

      expect(service.filename).to eq("invoice-2024-001.pdf")
    end

    it "handles invoice numbers with special characters" do
      invoice.number = "INV/2024/001"
      service = described_class.new(invoice: invoice, controller: controller)

      expect(service.filename).to eq("invoice-INV/2024/001.pdf")
    end
  end

  describe "template assigns" do
    it "includes invoice and settings in assigns" do
      service = described_class.new(invoice: invoice, controller: controller)

      expect(controller).to receive(:render_to_string).with(
        hash_including(
          assigns: hash_including(:invoice, :settings)
        )
      )

      allow(Grover).to receive(:new).and_return(instance_double(Grover, to_pdf: ""))
      service.generate
    end

    it "includes line_items with work_entries" do
      line_item = create(:invoice_line_item, invoice: invoice)
      service = described_class.new(invoice: invoice, controller: controller)

      expect(controller).to receive(:render_to_string) do |args|
        expect(args[:assigns][:line_items]).to be_present
      end

      allow(Grover).to receive(:new).and_return(instance_double(Grover, to_pdf: ""))
      service.generate
    end
  end
end
