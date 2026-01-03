class InvoicePdfService
  def initialize(invoice:, controller:)
    @invoice = invoice
    @controller = controller
    @settings = Setting.instance
  end

  def generate
    Grover.new(rendered_html, format: "A4").to_pdf
  end

  def filename
    "invoice-#{@invoice.number}.pdf"
  end

  private

  def rendered_html
    @controller.render_to_string(
      template: "invoices/pdf",
      layout: false,
      assigns: template_assigns
    )
  end

  def template_assigns
    {
      invoice: @invoice,
      settings: @settings,
      logo_data_url: LogoService.to_data_url(@settings),
      line_items: @invoice.line_items.includes(:work_entries),
      work_entries: @invoice.work_entries.includes(project: :client).order(date: :asc),
      qr_code_data_url: qr_code_data_url
    }
  end

  def qr_code_data_url
    qr_generator = PaymentQrCodeGenerator.new(invoice: @invoice, settings: @settings)
    qr_generator.to_data_url if qr_generator.available?
  end
end
