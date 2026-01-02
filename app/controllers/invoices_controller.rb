class InvoicesController < ApplicationController
  include InvoicesHelper

  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :finalize, :pdf ]

  def index
    render inertia: "Invoices/Index", props: {
      invoices: invoices_json,
      clients: clients_for_filter,
      filters: current_filters
    }
  end

  def show
    @settings = Setting.instance
    qr_generator = PaymentQrCodeGenerator.new(invoice: @invoice, settings: @settings)

    render inertia: "Invoices/Show", props: {
      invoice: invoice_json(@invoice),
      line_items: invoice_line_items_json(@invoice),
      work_entries: invoice_work_entries_json(@invoice),
      project_groups: invoice_project_groups(@invoice),
      settings: settings_json,
      qr_code: qr_generator.available? ? {
        data_url: qr_generator.to_data_url,
        format: qr_generator.format
      } : nil
    }
  end

  def new
    render inertia: "Invoices/New", props: {
      clients: clients_for_select,
      preview: preview_data
    }
  end

  def edit
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: "Cannot edit a finalized invoice."
      return
    end

    render inertia: "Invoices/Edit", props: {
      invoice: invoice_json(@invoice),
      line_items: invoice_line_items_json(@invoice),
      work_entries: invoice_work_entries_json(@invoice)
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
      redirect_to invoice_path(result[:invoice]), notice: "Invoice created successfully."
    else
      redirect_to new_invoice_path(invoice_params.to_h), alert: result[:errors].first
    end
  end

  def update
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: "Cannot update a finalized invoice."
      return
    end

    if @invoice.update(update_invoice_params)
      redirect_to invoice_path(@invoice), notice: "Invoice updated successfully."
    else
      redirect_to edit_invoice_path(@invoice), alert: @invoice.errors.full_messages.first
    end
  end

  def destroy
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: "Cannot delete a finalized invoice."
      return
    end

    # Unassociate work entries before destroying the invoice
    @invoice.work_entries.update_all(invoice_id: nil, status: :unbilled)
    @invoice.destroy

    redirect_to invoices_path, notice: "Invoice deleted successfully."
  end

  def finalize
    unless @invoice.draft?
      redirect_to invoice_path(@invoice), alert: "Invoice is already finalized."
      return
    end

    Invoice.transaction do
      @invoice.final!
      @invoice.work_entries.update_all(status: :invoiced)
    end

    redirect_to invoice_path(@invoice), notice: "Invoice finalized successfully."
  end

  def pdf
    @settings = Setting.instance
    @logo_data_url = logo_as_data_url(@settings)
    @line_items = @invoice.line_items.includes(:work_entries)
    @work_entries = @invoice.work_entries.includes(project: :client).order(date: :asc)

    qr_generator = PaymentQrCodeGenerator.new(invoice: @invoice, settings: @settings)
    @qr_code_data_url = qr_generator.to_data_url if qr_generator.available?

    html = render_to_string(
      template: "invoices/pdf",
      layout: false
    )

    pdf = Grover.new(html, format: "A4").to_pdf
    filename = "invoice-#{@invoice.number}.pdf"

    send_data pdf,
              filename: filename,
              type: "application/pdf",
              disposition: "attachment"
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
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

  def invoices_json
    filtered_invoices.map do |invoice|
      {
        id: invoice.id,
        number: invoice.number,
        status: invoice.status,
        issue_date: invoice.issue_date,
        due_date: invoice.due_date,
        period_start: invoice.period_start,
        period_end: invoice.period_end,
        total_hours: invoice.total_hours&.to_f,
        total_amount: invoice.total_amount&.to_f,
        currency: invoice.currency,
        client_id: invoice.client_id,
        client_name: invoice.client.name
      }
    end
  end

  def invoice_json(invoice)
    {
      id: invoice.id,
      number: invoice.number,
      status: invoice.status,
      issue_date: invoice.issue_date,
      due_date: invoice.due_date,
      period_start: invoice.period_start,
      period_end: invoice.period_end,
      total_hours: invoice.total_hours&.to_f,
      total_amount: invoice.total_amount&.to_f,
      subtotal: invoice.subtotal.to_f,
      total_vat: invoice.total_vat.to_f,
      grand_total: invoice.grand_total.to_f,
      vat_totals_by_rate: invoice.vat_totals_by_rate.transform_keys(&:to_f).transform_values(&:to_f),
      currency: invoice.currency,
      notes: invoice.notes,
      client_id: invoice.client_id,
      client_name: invoice.client.name,
      client_address: invoice.client.address,
      client_email: invoice.client.email,
      client_vat_id: invoice.client.vat_id,
      client_default_vat_rate: invoice.client.default_vat_rate&.to_f
    }
  end

  def invoice_line_items_json(invoice)
    invoice.line_items.map do |item|
      {
        id: item.id,
        line_type: item.line_type,
        description: item.description,
        quantity: item.quantity&.to_f,
        unit_price: item.unit_price&.to_f,
        amount: item.amount.to_f,
        vat_rate: item.vat_rate.to_f,
        vat_amount: item.vat_amount.to_f,
        position: item.position,
        work_entry_ids: item.work_entries.map(&:id)
      }
    end
  end

  def invoice_work_entries_json(invoice)
    invoice.work_entries.includes(project: :client).order(date: :asc).map do |entry|
      {
        id: entry.id,
        date: entry.date,
        hours: entry.hours&.to_f,
        amount: entry.amount&.to_f,
        entry_type: entry.entry_type,
        description: entry.description,
        calculated_amount: entry.calculated_amount&.to_f,
        project_id: entry.project_id,
        project_name: entry.project.name,
        effective_hourly_rate: entry.project.effective_hourly_rate&.to_f
      }
    end
  end

  def invoice_project_groups(invoice)
    invoice.work_entries.includes(project: :client).order(date: :asc).group_by(&:project).map do |project, entries|
      {
        project: {
          id: project.id,
          name: project.name,
          effective_hourly_rate: project.effective_hourly_rate&.to_f
        },
        entries: entries.map do |entry|
          {
            id: entry.id,
            date: entry.date,
            hours: entry.hours&.to_f,
            amount: entry.amount&.to_f,
            entry_type: entry.entry_type,
            description: entry.description,
            calculated_amount: entry.calculated_amount&.to_f
          }
        end,
        total_hours: entries.select(&:time?).sum { |e| e.hours || 0 }.to_f,
        total_amount: entries.sum { |e| e.calculated_amount || 0 }.to_f
      }
    end
  end

  def clients_for_filter
    Client.order(:name).map do |client|
      {
        id: client.id,
        name: client.name
      }
    end
  end

  def clients_for_select
    Client.includes(:projects).order(:name).map do |client|
      {
        id: client.id,
        name: client.name,
        currency: client.currency,
        hourly_rate: client.hourly_rate,
        default_vat_rate: client.default_vat_rate&.to_f,
        has_unbilled_entries: unbilled_entries_count(client) > 0
      }
    end
  end

  def unbilled_entries_count(client)
    WorkEntry.joins(:project)
             .where(projects: { client_id: client.id })
             .unbilled
             .count
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

  def settings_json
    settings = Setting.instance
    {
      company_name: settings.company_name,
      address: settings.address,
      email: settings.email,
      phone: settings.phone,
      vat_id: settings.vat_id,
      company_registration: settings.company_registration,
      bank_name: settings.bank_name,
      bank_account: settings.bank_account,
      bank_swift: settings.bank_swift,
      logo_url: settings.logo? ? url_for(settings.logo) : nil
    }
  end

  def logo_as_data_url(settings)
    return nil unless settings.logo?

    blob = settings.logo.blob
    content_type = blob.content_type
    base64_data = Base64.strict_encode64(blob.download)
    "data:#{content_type};base64,#{base64_data}"
  end
end
