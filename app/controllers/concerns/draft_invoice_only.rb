module DraftInvoiceOnly
  extend ActiveSupport::Concern

  private

  def require_draft_invoice
    return if @invoice.draft?

    redirect_to invoice_path(@invoice), alert: "Cannot modify a finalized invoice."
  end
end
