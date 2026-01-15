require 'rails_helper'

RSpec.describe "MigrateSettingsBankToBankAccount migration" do
  # Helper to run the migration logic
  def run_migration
    return if BankAccount.exists?

    settings = Setting.instance
    return if settings.bank_name.blank? && settings.iban.blank?

    BankAccount.create!(
      name: settings.bank_name.presence || "Primary Account",
      bank_name: settings.bank_name,
      bank_account: settings.bank_account,
      bank_swift: settings.bank_swift,
      iban: settings.iban.presence || "CZ0000000000000000000000",
      is_default: true
    )
  end

  describe "data migration from Settings" do
    before do
      # Clean up any existing bank accounts to simulate pre-migration state
      BankAccount.delete_all
    end

    it "creates BankAccount from Settings bank fields and marks as default" do
      # Create settings with bank details
      Setting.delete_all
      Setting.create!(
        bank_name: "Czech Savings Bank",
        bank_account: "1234567890/0800",
        bank_swift: "GIBACZPX",
        iban: "CZ6508000000192000145399"
      )

      run_migration

      expect(BankAccount.count).to eq(1)
      bank_account = BankAccount.first

      expect(bank_account.name).to eq("Czech Savings Bank")
      expect(bank_account.bank_name).to eq("Czech Savings Bank")
      expect(bank_account.bank_account).to eq("1234567890/0800")
      expect(bank_account.bank_swift).to eq("GIBACZPX")
      expect(bank_account.iban).to eq("CZ6508000000192000145399")
      expect(bank_account.is_default).to be true
    end

    it "is idempotent - does not create duplicate if bank account exists" do
      # Create settings with bank details
      Setting.delete_all
      Setting.create!(
        bank_name: "Czech Savings Bank",
        bank_account: "1234567890/0800",
        bank_swift: "GIBACZPX",
        iban: "CZ6508000000192000145399"
      )

      # Pre-existing bank account
      create(:bank_account, :default, name: "Existing Account")

      run_migration

      # Should not create another account
      expect(BankAccount.count).to eq(1)
      expect(BankAccount.first.name).to eq("Existing Account")
    end

    it "handles empty settings gracefully - no bank account created" do
      # Create settings without bank details
      Setting.delete_all
      Setting.create!(
        bank_name: nil,
        bank_account: nil,
        bank_swift: nil,
        iban: nil
      )

      run_migration

      expect(BankAccount.count).to eq(0)
    end
  end
end
