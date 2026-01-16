require 'rails_helper'

RSpec.describe ExchangeRate, type: :model do
  describe "validations" do
    subject { build(:exchange_rate) }

    it { is_expected.to be_valid }

    describe "base_currency" do
      it "requires base_currency to be present" do
        exchange_rate = build(:exchange_rate, base_currency: nil)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:base_currency]).to include("can't be blank")
      end

      it "allows valid 3-letter uppercase currency code" do
        %w[CZK EUR USD GBP CHF].each do |currency|
          exchange_rate = build(:exchange_rate, base_currency: currency)
          expect(exchange_rate).to be_valid, "Expected #{currency} to be valid"
        end
      end

      it "rejects lowercase currency codes" do
        exchange_rate = build(:exchange_rate, base_currency: "czk")
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:base_currency]).to include("must be 3 uppercase letters (e.g., CZK, EUR, USD)")
      end

      it "rejects invalid currency format" do
        exchange_rate = build(:exchange_rate, base_currency: "CZ")
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:base_currency]).to include("must be 3 uppercase letters (e.g., CZK, EUR, USD)")
      end
    end

    describe "quote_currency" do
      it "requires quote_currency to be present" do
        exchange_rate = build(:exchange_rate, quote_currency: nil)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:quote_currency]).to include("can't be blank")
      end

      it "allows valid 3-letter uppercase currency code" do
        %w[EUR USD GBP CHF JPY].each do |currency|
          exchange_rate = build(:exchange_rate, quote_currency: currency)
          expect(exchange_rate).to be_valid, "Expected #{currency} to be valid"
        end
      end

      it "rejects lowercase currency codes" do
        exchange_rate = build(:exchange_rate, quote_currency: "eur")
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:quote_currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
      end

      it "rejects invalid currency format" do
        exchange_rate = build(:exchange_rate, quote_currency: "EU")
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:quote_currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
      end
    end

    describe "rate" do
      it "requires rate to be present" do
        exchange_rate = build(:exchange_rate, rate: nil)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:rate]).to include("can't be blank")
      end

      it "requires rate to be greater than 0" do
        exchange_rate = build(:exchange_rate, rate: 0)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:rate]).to include("must be greater than 0")
      end

      it "rejects negative rate" do
        exchange_rate = build(:exchange_rate, rate: -1.5)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:rate]).to include("must be greater than 0")
      end

      it "allows positive rate" do
        exchange_rate = build(:exchange_rate, rate: 25.125)
        expect(exchange_rate).to be_valid
      end
    end

    describe "amount" do
      it "requires amount to be present" do
        exchange_rate = build(:exchange_rate, amount: nil)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:amount]).to include("can't be blank")
      end

      it "requires amount to be greater than 0" do
        exchange_rate = build(:exchange_rate, amount: 0)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:amount]).to include("must be greater than 0")
      end

      it "rejects negative amount" do
        exchange_rate = build(:exchange_rate, amount: -1)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:amount]).to include("must be greater than 0")
      end

      it "allows positive integer amount" do
        exchange_rate = build(:exchange_rate, amount: 100)
        expect(exchange_rate).to be_valid
      end
    end

    describe "date" do
      it "requires date to be present" do
        exchange_rate = build(:exchange_rate, date: nil)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:date]).to include("can't be blank")
      end
    end

    describe "uniqueness constraint on [base_currency, quote_currency, date]" do
      it "prevents duplicate base/quote/date combinations" do
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", date: Date.current)
        duplicate = build(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", date: Date.current)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:quote_currency]).to include("has already been taken")
      end

      it "allows same quote_currency on different dates" do
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", date: Date.current)
        different_date = build(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", date: Date.yesterday)
        expect(different_date).to be_valid
      end

      it "allows different quote_currencies on same date" do
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", date: Date.current)
        different_currency = build(:exchange_rate, base_currency: "CZK", quote_currency: "USD", date: Date.current)
        expect(different_currency).to be_valid
      end

      it "allows same quote_currency with different base_currency on same date" do
        create(:exchange_rate, base_currency: "CZK", quote_currency: "EUR", date: Date.current)
        different_base = build(:exchange_rate, base_currency: "USD", quote_currency: "EUR", date: Date.current)
        expect(different_base).to be_valid
      end
    end
  end

  describe "factory" do
    it "creates a valid exchange rate" do
      exchange_rate = build(:exchange_rate)
      expect(exchange_rate).to be_valid
    end

    it "creates a USD exchange rate with trait" do
      exchange_rate = build(:exchange_rate, :usd)
      expect(exchange_rate.quote_currency).to eq("USD")
    end

    it "creates a high amount exchange rate with trait" do
      exchange_rate = build(:exchange_rate, :high_amount)
      expect(exchange_rate.amount).to eq(100)
    end
  end
end
