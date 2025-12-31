class InvoiceLineItemsController < ApplicationController
  before_action :set_invoice
  before_action :ensure_draft_invoice
  before_action :set_line_item, only: [:update, :destroy, :reorder]

  def create
    @line_item = @invoice.line_items.build(line_item_params)
    @line_item.position = @invoice.line_items.maximum(:position).to_i + 1

    if @line_item.save
      @invoice.calculate_totals!
      redirect_to invoice_path(@invoice), notice: "Line item added successfully."
    else
      redirect_to invoice_path(@invoice), alert: @line_item.errors.full_messages.first
    end
  end

  def update
    if @line_item.update(line_item_params)
      @invoice.calculate_totals!
      redirect_to invoice_path(@invoice), notice: "Line item updated successfully."
    else
      redirect_to invoice_path(@invoice), alert: @line_item.errors.full_messages.first
    end
  end

  def destroy
    # Unlink associated work entries and mark them as unbilled
    @line_item.work_entries.each do |entry|
      entry.update!(invoice: nil, status: :unbilled)
    end

    @line_item.destroy
    @invoice.calculate_totals!

    redirect_to invoice_path(@invoice), notice: "Line item removed successfully."
  end

  def reorder
    direction = params[:direction]
    current_position = @line_item.position

    if direction == "up" && current_position > 0
      swap_with = @invoice.line_items.find_by(position: current_position - 1)
      if swap_with
        swap_positions(@line_item, swap_with)
      end
    elsif direction == "down"
      swap_with = @invoice.line_items.find_by(position: current_position + 1)
      if swap_with
        swap_positions(@line_item, swap_with)
      end
    end

    redirect_to invoice_path(@invoice)
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:invoice_id])
  end

  def ensure_draft_invoice
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: "Cannot modify a finalized invoice."
    end
  end

  def set_line_item
    @line_item = @invoice.line_items.find(params[:id])
  end

  def line_item_params
    params.require(:line_item).permit(:description, :amount, :line_type, :quantity, :unit_price)
  end

  def swap_positions(item1, item2)
    pos1 = item1.position
    pos2 = item2.position

    InvoiceLineItem.transaction do
      # Use a temporary position to avoid unique constraint issues if any
      item1.update!(position: -1)
      item2.update!(position: pos1)
      item1.update!(position: pos2)
    end
  end
end
