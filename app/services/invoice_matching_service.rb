# Service for matching incoming transactions to invoices.
#
# Matches transactions to invoices based on:
# - Exact reference match (variable symbol) to invoice number
# - Exact amount match to invoice total_amount
#
# Usage:
#   # Match all payable invoices to unmatched transactions
#   InvoiceMatchingService.match_all
#
class InvoiceMatchingService
  # Matches all payable invoices to unmatched income transactions.
  # Iterates over invoices (fewer) rather than transactions (many) for efficiency.
  # @return [Integer] number of invoices matched
  def self.match_all
    matched_count = 0

    Invoice.payable.find_each do |invoice|
      transaction = find_matching_transaction(invoice)
      next unless transaction

      link_invoice_to_transaction(invoice, transaction)
      matched_count += 1
    end

    matched_count
  end

  def self.find_matching_transaction(invoice)
    MoneyTransaction.income.unmatched.find_by(
      reference: invoice.number,
      amount: invoice.total_amount
    )
  end
  private_class_method :find_matching_transaction

  def self.link_invoice_to_transaction(invoice, transaction)
    Invoice.transaction do
      invoice.mark_as_paid!(transaction.transacted_on)
      transaction.update!(invoice_id: invoice.id)
    end
  end
  private_class_method :link_invoice_to_transaction
end
