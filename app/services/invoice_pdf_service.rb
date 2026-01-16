class InvoicePdfService
  def initialize(invoice:, controller:, locale: nil)
    @invoice = invoice
    @controller = controller
    @settings = Setting.instance
    @bank_account = invoice.bank_account || BankAccount.default
    @locale = locale || invoice.client&.locale || I18n.default_locale.to_s
  end

  def generate
    # Set locale for PDF rendering
    I18n.with_locale(@locale) do
      Grover.new(rendered_html, format: "A4").to_pdf
    end
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
      bank_account: @bank_account,
      logo_data_url: LogoService.to_data_url(@settings),
      line_items: @invoice.line_items.includes(:work_entries),
      work_entries: @invoice.work_entries.includes(project: :client).order(date: :asc),
      qr_code_data_url: qr_code_data_url
    }
  end

  def qr_code_data_url
    qr_generator = PaymentQrCodeGenerator.new(invoice: @invoice, settings: @settings, bank_account: @bank_account)
    qr_generator.to_data_url if qr_generator.available?
  end
end
