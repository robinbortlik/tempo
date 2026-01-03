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
end
