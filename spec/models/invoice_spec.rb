require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe "associations" do
    it "belongs to a client" do
      association = described_class.reflect_on_association(:client)
      expect(association.macro).to eq(:belongs_to)
    end

    it "has many work_entries" do
      association = described_class.reflect_on_association(:work_entries)
      expect(association.macro).to eq(:has_many)
    end

    it "has many line_items" do
      association = described_class.reflect_on_association(:line_items)
      expect(association.macro).to eq(:has_many)
    end

    it "nullifies work_entries when destroyed" do
      invoice = create(:invoice)
      work_entry = create(:work_entry, invoice: invoice)
      expect { invoice.destroy }.not_to change(WorkEntry, :count)
      expect(work_entry.reload.invoice_id).to be_nil
    end

    it "destroys line_items when destroyed" do
      invoice = create(:invoice)
      line_item = create(:invoice_line_item, invoice: invoice)
      expect { invoice.destroy }.to change(InvoiceLineItem, :count).by(-1)
    end

    it "is destroyed when client is destroyed" do
      client = create(:client)
      invoice = create(:invoice, client: client)
      expect { client.destroy }.to change(Invoice, :count).by(-1)
    end
  end

  describe "validations" do
    subject { build(:invoice) }

    it { is_expected.to be_valid }

    describe "number" do
      it "auto-generates number if nil on new record" do
        # The before_validation callback auto-generates a number
        invoice = build(:invoice, number: nil)
        invoice.valid?
        expect(invoice.number).to be_present
        expect(invoice.errors[:number]).to be_empty
      end

      it "requires number to be unique" do
        existing_invoice = create(:invoice, number: "2024-001")
        new_invoice = build(:invoice, number: "2024-001")
        expect(new_invoice).not_to be_valid
        expect(new_invoice.errors[:number]).to include("has already been taken")
      end
    end

    describe "client" do
      it "requires a client" do
        invoice = build(:invoice)
        invoice.client = nil
        expect(invoice).not_to be_valid
        expect(invoice.errors[:client]).to include("must exist")
      end
    end

    describe "currency" do
      it "allows blank currency" do
        invoice = build(:invoice, currency: nil)
        expect(invoice).to be_valid
      end

      it "allows valid 3-letter uppercase currency code" do
        %w[EUR USD GBP CHF JPY].each do |currency|
          invoice = build(:invoice, currency: currency)
          expect(invoice).to be_valid, "Expected #{currency} to be valid"
        end
      end

      it "rejects lowercase currency codes" do
        invoice = build(:invoice, currency: "eur")
        expect(invoice).not_to be_valid
        expect(invoice.errors[:currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
      end

      it "rejects invalid currency format" do
        invoice = build(:invoice, currency: "EU")
        expect(invoice).not_to be_valid
        expect(invoice.errors[:currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
      end
    end

    describe "total_hours" do
      it "allows nil total_hours" do
        invoice = build(:invoice, total_hours: nil)
        expect(invoice).to be_valid
      end

      it "allows zero total_hours" do
        invoice = build(:invoice, total_hours: 0)
        expect(invoice).to be_valid
      end

      it "allows positive total_hours" do
        invoice = build(:invoice, total_hours: 40.5)
        expect(invoice).to be_valid
      end

      it "rejects negative total_hours" do
        invoice = build(:invoice, total_hours: -5)
        expect(invoice).not_to be_valid
        expect(invoice.errors[:total_hours]).to include("must be greater than or equal to 0")
      end
    end

    describe "total_amount" do
      it "allows nil total_amount" do
        invoice = build(:invoice, total_amount: nil)
        expect(invoice).to be_valid
      end

      it "allows zero total_amount" do
        invoice = build(:invoice, total_amount: 0)
        expect(invoice).to be_valid
      end

      it "allows positive total_amount" do
        invoice = build(:invoice, total_amount: 5000.00)
        expect(invoice).to be_valid
      end

      it "rejects negative total_amount" do
        invoice = build(:invoice, total_amount: -100)
        expect(invoice).not_to be_valid
        expect(invoice.errors[:total_amount]).to include("must be greater than or equal to 0")
      end
    end

    describe "period dates" do
      it "allows period_end equal to period_start" do
        date = Date.current
        invoice = build(:invoice, period_start: date, period_end: date)
        expect(invoice).to be_valid
      end

      it "allows period_end after period_start" do
        invoice = build(:invoice, period_start: Date.current, period_end: 1.week.from_now.to_date)
        expect(invoice).to be_valid
      end

      it "rejects period_end before period_start" do
        invoice = build(:invoice, period_start: Date.current, period_end: 1.week.ago.to_date)
        expect(invoice).not_to be_valid
        expect(invoice.errors[:period_end]).to include("must be after or equal to period start")
      end

      it "allows nil period dates" do
        invoice = build(:invoice, period_start: nil, period_end: nil)
        expect(invoice).to be_valid
      end
    end

    describe "due date" do
      it "allows due_date equal to issue_date" do
        date = Date.current
        invoice = build(:invoice, issue_date: date, due_date: date)
        expect(invoice).to be_valid
      end

      it "allows due_date after issue_date" do
        invoice = build(:invoice, issue_date: Date.current, due_date: 30.days.from_now.to_date)
        expect(invoice).to be_valid
      end

      it "rejects due_date before issue_date" do
        invoice = build(:invoice, issue_date: Date.current, due_date: 1.week.ago.to_date)
        expect(invoice).not_to be_valid
        expect(invoice.errors[:due_date]).to include("must be after or equal to issue date")
      end

      it "allows nil dates" do
        invoice = build(:invoice, issue_date: nil, due_date: nil)
        expect(invoice).to be_valid
      end
    end
  end

  describe "enum status" do
    it "defines draft and final statuses" do
      expect(Invoice.statuses).to eq({ "draft" => 0, "final" => 1 })
    end

    it "defaults to draft" do
      invoice = Invoice.new
      expect(invoice.draft?).to be true
    end

    it "can be set to final" do
      invoice = build(:invoice, status: :final)
      expect(invoice.final?).to be true
    end

    it "provides scope methods for draft" do
      draft_invoice = create(:invoice, :draft)
      final_invoice = create(:invoice, :final)
      expect(Invoice.draft).to contain_exactly(draft_invoice)
    end

    it "provides scope methods for final" do
      draft_invoice = create(:invoice, :draft)
      final_invoice = create(:invoice, :final)
      expect(Invoice.final).to contain_exactly(final_invoice)
    end
  end

  describe "scopes" do
    describe ".for_year" do
      let!(:invoice_2024) { create(:invoice, number: "2024-001") }
      let!(:invoice_2025) { create(:invoice, number: "2025-001") }

      it "returns invoices for the specified year" do
        expect(Invoice.for_year(2024)).to contain_exactly(invoice_2024)
        expect(Invoice.for_year(2025)).to contain_exactly(invoice_2025)
      end
    end

    describe ".for_client" do
      let(:client1) { create(:client) }
      let(:client2) { create(:client) }
      let!(:invoice1) { create(:invoice, client: client1) }
      let!(:invoice2) { create(:invoice, client: client2) }

      it "returns invoices for the specified client" do
        expect(Invoice.for_client(client1)).to contain_exactly(invoice1)
        expect(Invoice.for_client(client2)).to contain_exactly(invoice2)
      end
    end
  end

  describe "before_create callback" do
    it "auto-generates invoice number if not provided" do
      client = create(:client)
      invoice = Invoice.new(client: client)
      invoice.save!
      expect(invoice.number).to match(/\A\d{4}-\d{3}\z/)
    end

    it "does not overwrite existing number" do
      invoice = build(:invoice, number: "CUSTOM-001")
      invoice.save!
      expect(invoice.number).to eq("CUSTOM-001")
    end

    it "generates sequential numbers" do
      client = create(:client)
      invoice1 = Invoice.create!(client: client)
      invoice2 = Invoice.create!(client: client)

      # Extract sequence numbers
      seq1 = invoice1.number.split("-").last.to_i
      seq2 = invoice2.number.split("-").last.to_i

      expect(seq2).to eq(seq1 + 1)
    end
  end

  describe "#calculate_totals" do
    let(:client) { create(:client, hourly_rate: 100.00) }
    let(:project) { create(:project, client: client, hourly_rate: 120.00) }
    let(:invoice) { create(:invoice, client: client) }

    context "with no work entries" do
      it "sets totals to zero" do
        invoice.calculate_totals
        expect(invoice.total_hours).to eq(0)
        expect(invoice.total_amount).to eq(0)
      end
    end

    context "with work entries" do
      before do
        create(:work_entry, invoice: invoice, project: project, hours: 8)
        create(:work_entry, invoice: invoice, project: project, hours: 4.5)
      end

      it "calculates total_hours from work entries" do
        invoice.calculate_totals
        expect(invoice.total_hours).to eq(12.5)
      end

      it "calculates total_amount from work entries" do
        invoice.calculate_totals
        # 8 hours * 120 + 4.5 hours * 120 = 960 + 540 = 1500
        expect(invoice.total_amount).to eq(1500.00)
      end

      it "returns self for chaining" do
        result = invoice.calculate_totals
        expect(result).to eq(invoice)
      end
    end

    context "with line_items present" do
      before do
        create(:invoice_line_item, :time_aggregate, invoice: invoice, quantity: 10, amount: 1200)
        create(:invoice_line_item, :fixed, invoice: invoice, amount: 500)
      end

      it "uses line_items for totals instead of work_entries" do
        invoice.calculate_totals
        expect(invoice.total_hours).to eq(10)
        expect(invoice.total_amount).to eq(1700)
      end
    end

    context "with work entries without hourly rate" do
      let(:client_no_rate) { create(:client, hourly_rate: nil) }
      let(:project_no_rate) { create(:project, client: client_no_rate, hourly_rate: nil) }
      let(:invoice_no_rate) { create(:invoice, client: client_no_rate) }

      before do
        create(:work_entry, invoice: invoice_no_rate, project: project_no_rate, hours: 8)
      end

      it "treats nil amounts as zero" do
        invoice_no_rate.calculate_totals
        expect(invoice_no_rate.total_hours).to eq(8)
        expect(invoice_no_rate.total_amount).to eq(0)
      end
    end
  end

  describe "#calculate_totals!" do
    let(:client) { create(:client, hourly_rate: 100.00) }
    let(:project) { create(:project, client: client, hourly_rate: 100.00) }
    let(:invoice) { create(:invoice, client: client) }

    before do
      create(:work_entry, invoice: invoice, project: project, hours: 10)
    end

    it "calculates and saves totals" do
      invoice.calculate_totals!
      invoice.reload
      expect(invoice.total_hours).to eq(10)
      expect(invoice.total_amount).to eq(1000.00)
    end
  end

  describe "VAT calculation methods" do
    let(:invoice) { create(:invoice) }

    before do
      create(:invoice_line_item, invoice: invoice, amount: 500.00, vat_rate: 21.00, position: 0)
      create(:invoice_line_item, invoice: invoice, amount: 300.00, vat_rate: 21.00, position: 1)
      create(:invoice_line_item, invoice: invoice, amount: 200.00, vat_rate: 0.00, position: 2)
    end

    describe "#subtotal" do
      it "sums all line item amounts" do
        expect(invoice.subtotal).to eq(1000.00)
      end
    end

    describe "#total_vat" do
      it "sums all line item VAT amounts" do
        # 500 * 0.21 = 105, 300 * 0.21 = 63, 200 * 0 = 0
        expect(invoice.total_vat).to eq(168.00)
      end
    end

    describe "#grand_total" do
      it "returns subtotal plus total VAT" do
        expect(invoice.grand_total).to eq(1168.00)
      end
    end

    describe "#vat_totals_by_rate" do
      it "groups VAT amounts correctly" do
        totals = invoice.vat_totals_by_rate
        # Keys are BigDecimals, so use to_f for comparison
        totals_by_float = totals.transform_keys(&:to_f)
        expect(totals_by_float[21.0]).to eq(168.00)
        expect(totals_by_float[0.0]).to eq(0.00)
      end
    end
  end

  describe "factory" do
    it "creates a valid invoice" do
      invoice = build(:invoice)
      expect(invoice).to be_valid
    end

    it "creates an invoice with associated client" do
      invoice = create(:invoice)
      expect(invoice.client).to be_present
    end

    it "creates a draft invoice by default" do
      invoice = build(:invoice)
      expect(invoice.draft?).to be true
    end

    it "creates a final invoice with trait" do
      invoice = build(:invoice, :final)
      expect(invoice.final?).to be true
    end

    it "creates an invoice with notes using trait" do
      invoice = build(:invoice, :with_notes)
      expect(invoice.notes).to be_present
    end

    it "creates a USD invoice with trait" do
      invoice = build(:invoice, :usd)
      expect(invoice.currency).to eq("USD")
    end

    it "creates an invoice with totals using trait" do
      invoice = build(:invoice, :with_totals)
      expect(invoice.total_hours).to eq(40.0)
      expect(invoice.total_amount).to eq(4800.00)
    end

    it "generates unique numbers with sequence" do
      invoice1 = create(:invoice)
      invoice2 = create(:invoice)
      expect(invoice1.number).not_to eq(invoice2.number)
    end
  end
end
