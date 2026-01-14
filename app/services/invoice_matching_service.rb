# Service for matching incoming transactions to invoices.
#
# Matches transactions to invoices based on:
# - Exact reference match (variable symbol) to invoice number
# - Exact amount match to invoice grand_total
#
# Usage:
#   # Match all unmatched income transactions
#   InvoiceMatchingService.match_all
#
#   # Match a specific transaction
#   service = InvoiceMatchingService.new(transaction)
#   result = service.match
#
class InvoiceMatchingService
  attr_reader :transaction

  def initialize(transaction)
    @transaction = transaction
  end

  # Class method to match all unmatched income transactions
  def self.match_all
    MoneyTransaction.income.unmatched.find_each do |transaction|
      new(transaction).match
    end
  end

  # Attempts to match the transaction to a payable invoice
  # @return [Hash] result with :success and :invoice or :error
  def match
    return { success: false, error: "Transaction already matched" } if transaction.invoice_id.present?
    return { success: false, error: "Not an income transaction" } unless transaction.income?
    return { success: false, error: "No reference" } if transaction.reference.blank?

    invoice = find_matching_invoice
    return { success: false, error: "No matching invoice found" } unless invoice

    Invoice.transaction do
      invoice.update!(status: :paid, paid_at: transaction.transacted_on)
      transaction.update!(invoice_id: invoice.id)
    end

    { success: true, invoice: invoice }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  end

  private

  def find_matching_invoice
    Invoice.payable.find_by(
      number: transaction.reference,
      total_amount: transaction.amount
    )
  end
end
