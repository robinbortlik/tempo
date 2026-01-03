# Public controller for client report portal
# Accessible via share_token, no authentication required
class ReportsController < ApplicationController
  # Skip authentication - this is a public endpoint
  allow_unauthenticated_access

  def show
    client = Client.find_by!(share_token: params[:share_token], sharing_enabled: true)
    service = ClientReportService.new(
      client: client,
      year: params[:year],
      month: params[:month]
    )

    render inertia: "Reports/Show", props: service.report.merge(settings: settings_data)
  end

  def invoice_pdf
    client = Client.find_by!(share_token: params[:share_token], sharing_enabled: true)
    @invoice = client.invoices.final.find(params[:invoice_id])
    @settings = Setting.instance
    @logo_data_url = logo_as_data_url(@settings)
    @line_items = @invoice.line_items.includes(:work_entries)
    @work_entries = @invoice.work_entries.includes(project: :client).order(date: :asc)

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

  def settings_data
    settings = Setting.instance
    {
      company_name: settings.company_name
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
