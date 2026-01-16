require 'rails_helper'

RSpec.describe ExchangeRate, type: :model do
  describe "validations" do
    subject { build(:exchange_rate) }

    it { is_expected.to be_valid }

    describe "currency" do
      it "requires currency to be present" do
        exchange_rate = build(:exchange_rate, currency: nil)
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:currency]).to include("can't be blank")
      end

      it "allows valid 3-letter uppercase currency code" do
        %w[EUR USD GBP CHF JPY CZK].each do |currency|
          exchange_rate = build(:exchange_rate, currency: currency)
          expect(exchange_rate).to be_valid, "Expected #{currency} to be valid"
        end
      end

      it "rejects lowercase currency codes" do
        exchange_rate = build(:exchange_rate, currency: "eur")
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
      end

      it "rejects invalid currency format" do
        exchange_rate = build(:exchange_rate, currency: "EU")
        expect(exchange_rate).not_to be_valid
        expect(exchange_rate.errors[:currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
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

    describe "uniqueness constraint on [currency, date]" do
      it "prevents duplicate currency/date combinations" do
        create(:exchange_rate, currency: "EUR", date: Date.current)
        duplicate = build(:exchange_rate, currency: "EUR", date: Date.current)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:currency]).to include("has already been taken")
      end

      it "allows same currency on different dates" do
        create(:exchange_rate, currency: "EUR", date: Date.current)
        different_date = build(:exchange_rate, currency: "EUR", date: Date.yesterday)
        expect(different_date).to be_valid
      end

      it "allows different currencies on same date" do
        create(:exchange_rate, currency: "EUR", date: Date.current)
        different_currency = build(:exchange_rate, currency: "USD", date: Date.current)
        expect(different_currency).to be_valid
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
      expect(exchange_rate.currency).to eq("USD")
    end

    it "creates a high amount exchange rate with trait" do
      exchange_rate = build(:exchange_rate, :high_amount)
      expect(exchange_rate.amount).to eq(100)
    end
  end
end
