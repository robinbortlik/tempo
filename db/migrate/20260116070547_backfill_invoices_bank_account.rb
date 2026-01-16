class BackfillInvoicesBankAccount < ActiveRecord::Migration[8.1]
  def up
    default_bank_account = BankAccount.find_by(is_default: true)
    return unless default_bank_account

    Invoice.where(bank_account_id: nil).update_all(bank_account_id: default_bank_account.id)
  end

  def down
    # No-op: we don't want to remove bank_account_id on rollback
  end
end
