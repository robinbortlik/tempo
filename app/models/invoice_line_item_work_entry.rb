class InvoiceLineItemWorkEntry < ApplicationRecord
  # Associations
  belongs_to :invoice_line_item
  belongs_to :work_entry
end
