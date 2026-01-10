class InvoicesController < ApplicationController
  include InvoicesHelper

  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :finalize, :pdf ]

  def index
    render inertia: "Invoices/Index", props: {
      invoices: InvoiceSerializer::List.new(filtered_invoices).serializable_hash,
      clients: ClientSerializer::ForFilter.new(Client.order(:name)).serializable_hash,
      filters: current_filters
    }
  end

  def show
    qr_generator = PaymentQrCodeGenerator.new(invoice: @invoice, settings: settings)
    entries_by_project = invoice_work_entries.group_by(&:project)

    render inertia: "Invoices/Show", props: {
      invoice: InvoiceSerializer.new(@invoice).serializable_hash,
      line_items: InvoiceLineItemSerializer.new(@invoice.line_items).serializable_hash,
      work_entries: WorkEntrySerializer::ForInvoice.new(invoice_work_entries).serializable_hash,
      project_groups: serialize_project_groups(entries_by_project),
      settings: SettingsSerializer::ForInvoice.new(settings, params: { url_helpers: self }).serializable_hash,
      qr_code: qr_generator.available? ? {
        data_url: qr_generator.to_data_url,
        format: qr_generator.format
      } : nil
    }
  end

  def new
    unbilled_counts = ClientStatsService.unbilled_counts_for_clients(Client.pluck(:id))
    clients = Client.includes(:projects).order(:name)

    render inertia: "Invoices/New", props: {
      clients: ClientSerializer::ForInvoiceSelect.new(clients, params: { unbilled_counts: unbilled_counts }).serializable_hash,
      preview: preview_data
    }
  end

  def edit
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: t("flash.invoices.cannot_edit_finalized")
      return
    end

    render inertia: "Invoices/Edit", props: {
      invoice: InvoiceSerializer.new(@invoice).serializable_hash,
      line_items: InvoiceLineItemSerializer.new(@invoice.line_items).serializable_hash,
      work_entries: WorkEntrySerializer::ForInvoice.new(invoice_work_entries).serializable_hash
    }
  end

  def create
    builder = InvoiceBuilder.new(
      client_id: invoice_params[:client_id],
      period_start: invoice_params[:period_start],
      period_end: invoice_params[:period_end],
      issue_date: invoice_params[:issue_date],
      due_date: invoice_params[:due_date],
      notes: invoice_params[:notes]
    )

    result = builder.create_draft

    if result[:success]
      redirect_to invoice_path(result[:invoice]), notice: t("flash.invoices.created")
    else
      redirect_to new_invoice_path(invoice_params.to_h), alert: result[:errors].first
    end
  end

  def update
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: t("flash.invoices.cannot_update_finalized")
      return
    end

    if @invoice.update(update_invoice_params)
      redirect_to invoice_path(@invoice), notice: t("flash.invoices.updated")
    else
      redirect_to edit_invoice_path(@invoice), alert: @invoice.errors.full_messages.to_sentence
    end
  end

  def destroy
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: t("flash.invoices.cannot_delete_finalized")
      return
    end

    @invoice.work_entries.update_all(invoice_id: nil, status: :unbilled)
    @invoice.destroy

    redirect_to invoices_path, notice: t("flash.invoices.deleted")
  end

  def finalize
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: t("flash.invoices.already_finalized")
      return
    end

    Invoice.transaction do
      @invoice.final!
      @invoice.work_entries.update_all(status: :invoiced)
    end

    redirect_to invoice_path(@invoice), notice: t("flash.invoices.finalized")
  end

  def pdf
    pdf_service = InvoicePdfService.new(invoice: @invoice, controller: self)

    send_data pdf_service.generate,
              filename: pdf_service.filename,
              type: "application/pdf",
              disposition: "attachment"
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def settings
    @settings ||= Setting.instance
  end

  def invoice_params
    params.require(:invoice).permit(
      :client_id,
      :period_start,
      :period_end,
      :issue_date,
      :due_date,
      :notes
    )
  end

  def update_invoice_params
    params.require(:invoice).permit(
      :issue_date,
      :due_date,
      :notes
    )
  end

  def filtered_invoices
    invoices = Invoice.includes(:client).order(issue_date: :desc, created_at: :desc)
    invoices = invoices.where(status: params[:status]) if params[:status].present?
    invoices = invoices.for_client(params[:client_id]) if params[:client_id].present?
    invoices = invoices.for_year(params[:year]) if params[:year].present?
    invoices
  end

  def invoice_work_entries
    @invoice.work_entries.includes(project: :client).order(date: :asc)
  end

  def serialize_project_groups(entries_by_project)
    entries_by_project.map do |project, entries|
      InvoiceSerializer::ProjectGroup.new({ project: project, entries: entries }).serializable_hash
    end
  end

  def current_filters
    {
      status: params[:status],
      client_id: params[:client_id]&.to_i,
      year: params[:year]
    }
  end

  def preview_data
    return nil unless params[:client_id].present? && params[:period_start].present? && params[:period_end].present?

    begin
      builder = InvoiceBuilder.new(
        client_id: params[:client_id],
        period_start: params[:period_start],
        period_end: params[:period_end],
        issue_date: params[:issue_date],
        due_date: params[:due_date]
      )
      builder.preview
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
