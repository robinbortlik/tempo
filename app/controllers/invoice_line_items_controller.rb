class InvoiceLineItemsController < ApplicationController
  before_action :set_invoice
  before_action :ensure_draft_invoice
  before_action :set_line_item, only: [ :update, :destroy, :reorder ]

  def create
    @line_item = @invoice.line_items.build(line_item_params)
    @line_item.position = position_manager.next_position

    if @line_item.save
      @invoice.calculate_totals!
      redirect_to invoice_path(@invoice), notice: t("flash.invoice_line_items.added")
    else
      redirect_to invoice_path(@invoice), alert: @line_item.errors.full_messages.to_sentence
    end
  end

  def update
    if @line_item.update(line_item_params)
      @invoice.calculate_totals!
      redirect_to invoice_path(@invoice), notice: t("flash.invoice_line_items.updated")
    else
      redirect_to invoice_path(@invoice), alert: @line_item.errors.full_messages.to_sentence
    end
  end

  def destroy
    # Unlink associated work entries and mark them as unbilled
    @line_item.work_entries.each do |entry|
      entry.update!(invoice: nil, status: :unbilled)
    end

    @line_item.destroy
    @invoice.calculate_totals!

    redirect_to invoice_path(@invoice), notice: t("flash.invoice_line_items.removed")
  end

  def reorder
    position_manager.reorder(@line_item, params[:direction])
    redirect_to invoice_path(@invoice)
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:invoice_id])
  end

  def ensure_draft_invoice
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: t("flash.invoices.cannot_modify_finalized")
    end
  end

  def set_line_item
    @line_item = @invoice.line_items.find(params[:id])
  end

  def line_item_params
    params.require(:line_item).permit(:description, :amount, :line_type, :quantity, :unit_price, :vat_rate)
  end

  def position_manager
    @position_manager ||= PositionManager.new(@invoice.line_items)
  end
end
