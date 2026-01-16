class DeletionValidator
  def self.can_delete_client?(client)
    return { valid: false, error: "Cannot delete client with associated projects or invoices." } if client.projects.exists?
    return { valid: false, error: "Cannot delete client with associated projects or invoices." } if client.invoices.exists?
    { valid: true }
  end

  def self.can_delete_project?(project)
    return { valid: false, error: "Cannot delete project with invoiced work entries." } if project.work_entries.invoiced.exists?
    { valid: true }
  end

  def self.can_delete_bank_account?(bank_account)
    return { valid: false, error: "Cannot delete bank account with associated clients." } if bank_account.clients.exists?
    return { valid: false, error: "Cannot delete the only default bank account." } if bank_account.is_default && BankAccount.count == 1
    { valid: true }
  end
end
