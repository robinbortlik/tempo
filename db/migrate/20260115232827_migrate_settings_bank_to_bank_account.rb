class MigrateSettingsBankToBankAccount < ActiveRecord::Migration[8.1]
  def up
    # Skip if bank accounts already exist (idempotent)
    return if BankAccount.exists?

    # Get existing settings
    settings = Setting.first
    return unless settings

    # Skip if no bank details in settings
    return if settings.bank_name.blank? && settings.iban.blank?

    # Create bank account from settings
    BankAccount.create!(
      name: settings.bank_name.presence || "Primary Account",
      bank_name: settings.bank_name,
      bank_account: settings.bank_account,
      bank_swift: settings.bank_swift,
      iban: settings.iban.presence || "CZ0000000000000000000000",
      is_default: true
    )
  end

  def down
    # Do not delete bank accounts on rollback - keep old Settings fields for safety
    # This migration is data-only and non-destructive
  end
end
