module DraftInvoiceOnly
  extend ActiveSupport::Concern

  private

  def require_draft_invoice
    return if @invoice.draft?

    redirect_to invoice_path(@invoice), alert: I18n.t("flash.invoices.cannot_modify_finalized")
  end
end
