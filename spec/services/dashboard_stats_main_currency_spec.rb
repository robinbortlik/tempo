require 'rails_helper'

RSpec.describe DashboardStatsService, "main currency totals" do
  let(:service) { described_class.new }
  let(:setting) { Setting.instance }
  let(:current_year) { Date.current.year }

  before do
    setting.update!(main_currency: "CZK")
  end

  describe "#total_in_main_currency" do
    context "when paid invoices have exchange rates available" do
      it "sums main_currency_amount for paid invoices in current year" do
        client = create(:client, currency: "EUR")

        # Paid invoice with exchange rate
        invoice1 = create(:invoice, :paid, client: client, currency: "EUR",
          issue_date: Date.new(current_year, 1, 15))
        create(:invoice_line_item, invoice: invoice1, amount: 1000.00, vat_rate: 0)
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", rate: 25.0, amount: 1, date: Date.new(current_year, 1, 15))

        # Another paid invoice with different date
        invoice2 = create(:invoice, :paid, client: client, currency: "EUR",
          issue_date: Date.new(current_year, 2, 10))
        create(:invoice_line_item, invoice: invoice2, amount: 2000.00, vat_rate: 0)
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", rate: 24.5, amount: 1, date: Date.new(current_year, 2, 10))

        result = service.total_in_main_currency

        # 1000 * 25.0 + 2000 * 24.5 = 25000 + 49000 = 74000
        expect(result[:amount]).to eq(74000.0)
        expect(result[:missing_exchange_rates]).to be false
      end
    end

    context "when invoices are in main currency" do
      it "includes them without conversion" do
        client = create(:client, currency: "CZK")

        invoice = create(:invoice, :paid, client: client, currency: "CZK",
          issue_date: Date.new(current_year, 1, 5),
          due_date: Date.new(current_year, 2, 5))
        create(:invoice_line_item, invoice: invoice, amount: 50000.00, vat_rate: 0)

        result = service.total_in_main_currency

        expect(result[:amount]).to eq(50000.0)
        expect(result[:missing_exchange_rates]).to be false
      end
    end

    context "when some invoices lack exchange rates" do
      it "sets missing_exchange_rates flag to true" do
        client = create(:client, currency: "EUR")

        # Invoice with exchange rate
        invoice1 = create(:invoice, :paid, client: client, currency: "EUR",
          issue_date: Date.new(current_year, 1, 15),
          due_date: Date.new(current_year, 2, 15))
        create(:invoice_line_item, invoice: invoice1, amount: 1000.00, vat_rate: 0)
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", rate: 25.0, amount: 1, date: Date.new(current_year, 1, 15))

        # Invoice WITHOUT exchange rate (missing rate for this date)
        invoice2 = create(:invoice, :paid, client: client, currency: "EUR",
          issue_date: Date.new(current_year, 1, 20),
          due_date: Date.new(current_year, 2, 20))
        create(:invoice_line_item, invoice: invoice2, amount: 2000.00, vat_rate: 0)

        result = service.total_in_main_currency

        # Only invoice1 can be converted: 1000 * 25.0 = 25000
        expect(result[:amount]).to eq(25000.0)
        expect(result[:missing_exchange_rates]).to be true
      end
    end

    context "when excluding non-paid invoices" do
      it "only includes paid invoices, not draft or final" do
        client = create(:client, currency: "EUR")

        # Paid invoice
        paid_invoice = create(:invoice, :paid, client: client, currency: "EUR",
          issue_date: Date.new(current_year, 1, 15))
        create(:invoice_line_item, invoice: paid_invoice, amount: 1000.00, vat_rate: 0)
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", rate: 25.0, amount: 1, date: Date.new(current_year, 1, 15))

        # Draft invoice (should be excluded)
        draft_invoice = create(:invoice, :draft, client: client, currency: "EUR",
          issue_date: Date.new(current_year, 1, 16))
        create(:invoice_line_item, invoice: draft_invoice, amount: 5000.00, vat_rate: 0)
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", rate: 25.0, amount: 1, date: Date.new(current_year, 1, 16))

        # Final invoice (should be excluded)
        final_invoice = create(:invoice, :final, client: client, currency: "EUR",
          issue_date: Date.new(current_year, 1, 17))
        create(:invoice_line_item, invoice: final_invoice, amount: 3000.00, vat_rate: 0)
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", rate: 25.0, amount: 1, date: Date.new(current_year, 1, 17))

        result = service.total_in_main_currency

        # Only paid invoice: 1000 * 25.0 = 25000
        expect(result[:amount]).to eq(25000.0)
      end
    end

    context "when no paid invoices exist" do
      it "returns zero with no missing rates" do
        result = service.total_in_main_currency

        expect(result[:amount]).to eq(0.0)
        expect(result[:missing_exchange_rates]).to be false
      end
    end
  end

  describe "#stats" do
    it "includes total_in_main_currency in the stats hash" do
      result = service.stats

      expect(result).to have_key(:total_in_main_currency)
      expect(result[:total_in_main_currency]).to have_key(:amount)
      expect(result[:total_in_main_currency]).to have_key(:missing_exchange_rates)
    end
  end
end
