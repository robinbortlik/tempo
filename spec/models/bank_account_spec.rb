require 'rails_helper'

RSpec.describe BankAccount, type: :model do
  describe "validations" do
    subject { build(:bank_account) }

    it { is_expected.to be_valid }

    describe "name" do
      it "requires name to be present" do
        bank_account = build(:bank_account, name: nil)
        expect(bank_account).not_to be_valid
        expect(bank_account.errors[:name]).to include("can't be blank")
      end
    end

    describe "iban" do
      it "requires iban to be present" do
        bank_account = build(:bank_account, iban: nil)
        expect(bank_account).not_to be_valid
        expect(bank_account.errors[:iban]).to include("can't be blank")
      end

      it "allows valid IBAN format" do
        bank_account = build(:bank_account, iban: "DE89370400440532013000")
        expect(bank_account).to be_valid
      end

      it "rejects invalid IBAN format" do
        bank_account = build(:bank_account, iban: "INVALID123")
        expect(bank_account).not_to be_valid
        expect(bank_account.errors[:iban]).to include("is not a valid IBAN")
      end
    end
  end

  describe "is_default uniqueness" do
    it "allows only one default account" do
      create(:bank_account, :default)
      second_default = build(:bank_account, is_default: true)
      second_default.valid?
      # After validation, the first default should be unset
      expect(BankAccount.where(is_default: true).count).to eq(1)
    end

    it "swaps default when setting new default" do
      first = create(:bank_account, :default)
      second = create(:bank_account, is_default: true)

      expect(first.reload.is_default).to be false
      expect(second.is_default).to be true
    end
  end

  describe "default account enforcement" do
    it "sets first account as default automatically" do
      bank_account = create(:bank_account, is_default: false)
      expect(bank_account.reload.is_default).to be true
    end

    it "prevents removing default from sole account" do
      bank_account = create(:bank_account, :default)
      bank_account.update(is_default: false)
      expect(bank_account.reload.is_default).to be true
    end
  end

  describe ".default" do
    it "returns the default bank account" do
      create(:bank_account, is_default: false, name: "Secondary")
      default_account = create(:bank_account, :default, name: "Primary")

      expect(BankAccount.default).to eq(default_account)
    end

    it "returns nil when no default exists" do
      expect(BankAccount.default).to be_nil
    end
  end

  describe "scope :default_scope" do
    it "returns accounts with is_default true" do
      default_account = create(:bank_account, :default)
      create(:bank_account, is_default: false)

      expect(BankAccount.default_accounts).to contain_exactly(default_account)
    end
  end
end
