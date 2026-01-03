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

    render inertia: "Reports/Show", props: service.report.merge(
      settings: { company_name: settings.company_name }
    )
  end

  def invoice_pdf
    client = Client.find_by!(share_token: params[:share_token], sharing_enabled: true)
    invoice = client.invoices.final.find(params[:invoice_id])

    pdf_service = InvoicePdfService.new(invoice: invoice, controller: self)

    send_data pdf_service.generate,
              filename: pdf_service.filename,
              type: "application/pdf",
              disposition: "attachment"
  end

  private

  def settings
    @settings ||= Setting.instance
  end
end
