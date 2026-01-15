require 'rails_helper'

RSpec.describe MoneyTransactionFilterService do
  describe "#filter" do
    context "period filtering" do
      it "filters by year and month using for_period scope" do
        jan_transaction = create(:money_transaction, transacted_on: Date.new(2026, 1, 15))
        feb_transaction = create(:money_transaction, transacted_on: Date.new(2026, 2, 10))

        service = described_class.new(params: { year: 2026, month: 1 })
        result = service.filter

        expect(result).to include(jan_transaction)
        expect(result).not_to include(feb_transaction)
      end

      it "filters by year only when month not provided" do
        transaction_2026 = create(:money_transaction, transacted_on: Date.new(2026, 6, 15))
        transaction_2025 = create(:money_transaction, transacted_on: Date.new(2025, 3, 10))

        service = described_class.new(params: { year: 2026 })
        result = service.filter

        expect(result).to include(transaction_2026)
        expect(result).not_to include(transaction_2025)
      end
    end

    context "transaction_type filtering" do
      it "filters by transaction_type income" do
        income = create(:money_transaction, :income)
        expense = create(:money_transaction, :expense)

        service = described_class.new(params: { transaction_type: "income" })
        result = service.filter

        expect(result).to include(income)
        expect(result).not_to include(expense)
      end

      it "filters by transaction_type expense" do
        income = create(:money_transaction, :income)
        expense = create(:money_transaction, :expense)

        service = described_class.new(params: { transaction_type: "expense" })
        result = service.filter

        expect(result).to include(expense)
        expect(result).not_to include(income)
      end
    end

    context "description filtering" do
      it "filters by description using case-insensitive search" do
        matching = create(:money_transaction, description: "Payment from ACME Corp")
        non_matching = create(:money_transaction, description: "Office supplies")

        service = described_class.new(params: { description: "acme" })
        result = service.filter

        expect(result).to include(matching)
        expect(result).not_to include(non_matching)
      end
    end
  end

  describe "#available_years" do
    it "returns years with transactions plus current year, sorted descending" do
      create(:money_transaction, transacted_on: Date.new(2024, 5, 10))
      create(:money_transaction, transacted_on: Date.new(2022, 3, 15))

      service = described_class.new(params: {})
      years = service.available_years

      expect(years).to include(2024, 2022, Date.current.year)
      expect(years).to eq(years.sort.reverse)
    end
  end

  describe "#summary" do
    it "returns correct totals for income, expenses, net balance, and count" do
      create(:money_transaction, :income, amount: 1000)
      create(:money_transaction, :income, amount: 500)
      create(:money_transaction, :expense, amount: 300)

      service = described_class.new(params: {})

      expect(service.summary).to eq({
        total_income: 1500.0,
        total_expenses: 300.0,
        net_balance: 1200.0,
        transaction_count: 3
      })
    end
  end
end
