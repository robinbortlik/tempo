require 'rails_helper'

RSpec.describe Invoice, "#main_currency_amount" do
  let(:setting) { Setting.instance }

  before do
    setting.update!(main_currency: "CZK")
  end

  describe "when invoice currency matches main currency" do
    it "returns the original grand_total without conversion" do
      invoice = create(:invoice, currency: "CZK")
      create(:invoice_line_item, invoice: invoice, amount: 1000.00, vat_rate: 0)

      expect(invoice.main_currency_amount).to eq(1000.00)
    end
  end

  describe "when exchange rate is available" do
    it "converts grand_total using the exchange rate from issue_date" do
      invoice = create(:invoice, currency: "EUR", issue_date: Date.new(2026, 1, 15))
      create(:invoice_line_item, invoice: invoice, amount: 1000.00, vat_rate: 0)

      # Create exchange rate for EUR on the invoice's issue_date
      # Rate 25.125 means 1 EUR = 25.125 CZK
      create(:exchange_rate, currency: "EUR", rate: 25.125, amount: 1, date: Date.new(2026, 1, 15))

      # 1000 EUR * (25.125 / 1) = 25125 CZK
      expect(invoice.main_currency_amount).to eq(25125.0)
    end

    it "handles rates with amount > 1 (e.g., JPY)" do
      invoice = create(:invoice, currency: "JPY", issue_date: Date.new(2026, 1, 15))
      create(:invoice_line_item, invoice: invoice, amount: 10000.00, vat_rate: 0)

      # JPY rate: 100 JPY = 15.30 CZK
      create(:exchange_rate, currency: "JPY", rate: 15.30, amount: 100, date: Date.new(2026, 1, 15))

      # 10000 JPY * (15.30 / 100) = 1530 CZK
      expect(invoice.main_currency_amount).to eq(1530.0)
    end
  end

  describe "when exchange rate is not available" do
    it "returns nil when no exchange rate exists for the date" do
      invoice = create(:invoice, currency: "EUR", issue_date: Date.new(2026, 1, 15))
      create(:invoice_line_item, invoice: invoice, amount: 1000.00, vat_rate: 0)

      # No exchange rate for this date
      create(:exchange_rate, currency: "EUR", rate: 25.125, amount: 1, date: Date.new(2026, 1, 10))

      expect(invoice.main_currency_amount).to be_nil
    end

    it "returns nil when no exchange rate exists for the currency" do
      invoice = create(:invoice, currency: "CHF", issue_date: Date.new(2026, 1, 15))
      create(:invoice_line_item, invoice: invoice, amount: 1000.00, vat_rate: 0)

      # Exchange rate exists for EUR but not CHF
      create(:exchange_rate, currency: "EUR", rate: 25.125, amount: 1, date: Date.new(2026, 1, 15))

      expect(invoice.main_currency_amount).to be_nil
    end
  end

  describe "when invoice currency is nil" do
    it "returns nil" do
      invoice = create(:invoice, currency: nil, issue_date: Date.new(2026, 1, 15))
      create(:invoice_line_item, invoice: invoice, amount: 1000.00, vat_rate: 0)

      expect(invoice.main_currency_amount).to be_nil
    end
  end
end
