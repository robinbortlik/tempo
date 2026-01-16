require 'rails_helper'

RSpec.describe Setting, type: :model do
  describe "validations" do
    subject { build(:setting) }

    it { is_expected.to be_valid }

    describe "email" do
      it "allows blank email" do
        setting = build(:setting, email: nil)
        expect(setting).to be_valid
      end

      it "allows valid email format" do
        setting = build(:setting, email: "valid@example.com")
        expect(setting).to be_valid
      end

      it "rejects invalid email format" do
        setting = build(:setting, email: "invalid-email")
        expect(setting).not_to be_valid
        expect(setting.errors[:email]).to include("must be a valid email address")
      end
    end

    describe "invoice_message" do
      it "allows blank invoice_message" do
        setting = build(:setting, invoice_message: nil)
        expect(setting).to be_valid
      end

      it "allows invoice_message at 500 characters" do
        setting = build(:setting, invoice_message: "a" * 500)
        expect(setting).to be_valid
      end

      it "rejects invoice_message exceeding 500 characters" do
        setting = build(:setting, invoice_message: "a" * 501)
        expect(setting).not_to be_valid
        expect(setting.errors[:invoice_message]).to include("is too long (maximum is 500 characters)")
      end
    end

    describe "main_currency" do
      it "allows blank main_currency" do
        setting = build(:setting, main_currency: nil)
        expect(setting).to be_valid
      end

      it "allows valid 3-letter uppercase currency code" do
        %w[CZK EUR USD GBP].each do |currency|
          setting = build(:setting, main_currency: currency)
          expect(setting).to be_valid, "Expected #{currency} to be valid"
        end
      end

      it "rejects lowercase currency codes" do
        setting = build(:setting, main_currency: "czk")
        expect(setting).not_to be_valid
        expect(setting.errors[:main_currency]).to include("must be 3 uppercase letters (e.g., CZK, EUR, USD)")
      end

      it "rejects invalid currency format" do
        setting = build(:setting, main_currency: "CZ")
        expect(setting).not_to be_valid
        expect(setting.errors[:main_currency]).to include("must be 3 uppercase letters (e.g., CZK, EUR, USD)")
      end

      it "defaults to CZK in database" do
        setting = Setting.create!
        expect(setting.main_currency).to eq("CZK")
      end
    end
  end

  describe ".instance (singleton pattern)" do
    it "creates a new record if none exists" do
      expect { Setting.instance }.to change(Setting, :count).by(1)
    end

    it "returns the existing record if one exists" do
      existing = create(:setting)
      expect(Setting.instance).to eq(existing)
    end

    it "does not create multiple records" do
      Setting.instance
      Setting.instance
      expect(Setting.count).to eq(1)
    end

    it "returns the same record on subsequent calls" do
      first_call = Setting.instance
      second_call = Setting.instance
      expect(first_call.id).to eq(second_call.id)
    end
  end

  describe "attributes" do
    subject { build(:setting) }

    it "stores company_name" do
      subject.company_name = "Test Company"
      expect(subject.company_name).to eq("Test Company")
    end

    it "stores address" do
      subject.address = "123 Test Street"
      expect(subject.address).to eq("123 Test Street")
    end

    it "stores phone" do
      subject.phone = "+1-555-1234"
      expect(subject.phone).to eq("+1-555-1234")
    end

    it "stores vat_id" do
      subject.vat_id = "VAT123456"
      expect(subject.vat_id).to eq("VAT123456")
    end

    it "stores company_registration" do
      subject.company_registration = "REG789"
      expect(subject.company_registration).to eq("REG789")
    end
  end

  describe "logo attachment" do
    it "can have a logo attached" do
      setting = build(:setting, :with_logo)
      expect(setting.logo).to be_attached
    end

    it "can be created without a logo" do
      setting = create(:setting)
      expect(setting.logo).not_to be_attached
    end

    describe "#logo?" do
      it "returns true when logo is attached" do
        setting = build(:setting, :with_logo)
        expect(setting.logo?).to be true
      end

      it "returns false when logo is not attached" do
        setting = build(:setting)
        expect(setting.logo?).to be false
      end
    end
  end

  describe "factory" do
    it "creates a valid setting" do
      setting = build(:setting)
      expect(setting).to be_valid
    end

    it "creates a minimal setting with nil values" do
      setting = build(:setting, :minimal)
      expect(setting).to be_valid
      expect(setting.company_name).to be_nil
    end

    it "creates a setting with logo" do
      setting = build(:setting, :with_logo)
      expect(setting.logo).to be_attached
    end
  end
end
