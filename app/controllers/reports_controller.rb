# Public controller for client report portal
# Accessible via share_token, no authentication required
class ReportsController < ApplicationController
  # Skip authentication - this is a public endpoint
  allow_unauthenticated_access

  before_action :set_client
  before_action :set_client_locale

  def show
    service = ClientReportService.new(
      client: @client,
      year: params[:year],
      month: params[:month]
    )

    render inertia: "Reports/Show", props: service.report.merge(
      settings: { company_name: settings.company_name },
      locale: client_locale
    )
  end

  def invoice_pdf
    invoice = @client.invoices.final.find(params[:invoice_id])

    pdf_service = InvoicePdfService.new(
      invoice: invoice,
      controller: self,
      locale: client_locale
    )

    send_data pdf_service.generate,
              filename: pdf_service.filename,
              type: "application/pdf",
              disposition: "attachment"
  end

  private

  def set_client
    @client = Client.find_by!(share_token: params[:share_token], sharing_enabled: true)
  end

  def settings
    @settings ||= Setting.instance
  end

  # Set Rails I18n locale from client's locale setting
  def set_client_locale
    I18n.locale = client_locale
  end

  # Client's locale is the primary source, with fallbacks
  def client_locale
    @client_locale ||= begin
      locale = @client.locale || params[:locale] || extract_locale_from_accept_language_header
      I18n.available_locales.map(&:to_s).include?(locale) ? locale : I18n.default_locale.to_s
    end
  end

  def extract_locale_from_accept_language_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/).first
  end
end
