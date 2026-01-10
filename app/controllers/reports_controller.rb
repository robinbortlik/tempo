# Public controller for client report portal
# Accessible via share_token, no authentication required
class ReportsController < ApplicationController
  # Skip authentication - this is a public endpoint
  allow_unauthenticated_access

  before_action :set_public_locale

  def show
    client = Client.find_by!(share_token: params[:share_token], sharing_enabled: true)
    service = ClientReportService.new(
      client: client,
      year: params[:year],
      month: params[:month]
    )

    render inertia: "Reports/Show", props: service.report.merge(
      settings: { company_name: settings.company_name },
      locale: public_locale
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

  # For public pages, support locale via query param, cookie, or browser preference
  def set_public_locale
    I18n.locale = public_locale
  end

  def public_locale
    @public_locale ||= begin
      locale = params[:locale] || cookies[:locale] || extract_locale_from_accept_language_header
      I18n.available_locales.map(&:to_s).include?(locale) ? locale : I18n.default_locale.to_s
    end
  end

  def extract_locale_from_accept_language_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/).first
  end
end
