# Generates QR codes for invoice payments
# Supports EPC QR Code (EUR/SEPA) and Czech QR Platba (SPAYD) for CZK
class PaymentQrCodeGenerator
  SUPPORTED_CURRENCIES = %w[EUR CZK].freeze

  attr_reader :invoice, :settings

  def initialize(invoice:, settings:)
    @invoice = invoice
    @settings = settings
  end

  # Check if QR code can be generated
  def available?
    settings.iban.present? &&
      SUPPORTED_CURRENCIES.include?(invoice.currency) &&
      invoice.grand_total.to_f > 0
  end

  # Generate QR code as SVG data URL
  def to_data_url
    return nil unless available?

    payload = build_payload
    svg = generate_qr_svg(payload)
    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end

  # Get the payment format being used
  def format
    return nil unless available?

    case invoice.currency
    when "EUR"
      :epc
    when "CZK"
      :spayd
    end
  end

  private

  def build_payload
    case invoice.currency
    when "EUR"
      build_epc_payload
    when "CZK"
      build_spayd_payload
    end
  end

  # EPC QR Code format (European Payments Council standard version 002)
  def build_epc_payload
    [
      "BCD",                                          # Service Tag
      "002",                                          # Version
      "1",                                            # Character set (UTF-8)
      "SCT",                                          # Identification (SEPA Credit Transfer)
      sanitize_bic(settings.bank_swift),              # BIC (optional)
      truncate(settings.company_name || "", 70),      # Beneficiary Name
      sanitize_iban(settings.iban),                   # IBAN
      format_epc_amount(invoice.grand_total),         # Amount
      "",                                             # Purpose (optional)
      "",                                             # Remittance (Structured) - empty
      truncate(invoice.number, 140)                   # Remittance (Unstructured) - Reference
    ].join("\n")
  end

  # Czech QR Platba (SPAYD) format
  def build_spayd_payload
    parts = [
      "SPD*1.0",
      "ACC:#{sanitize_iban(settings.iban)}#{bic_suffix}",
      "AM:#{format_spayd_amount(invoice.grand_total)}",
      "CC:CZK",
      "MSG:#{sanitize_spayd_text(invoice.number)}"
    ]

    # Add variable symbol if extractable from invoice number
    vs = extract_variable_symbol(invoice.number)
    parts << "X-VS:#{vs}" if vs.present?

    parts.join("*")
  end

  def sanitize_iban(iban)
    iban.to_s.gsub(/\s+/, "")
  end

  def sanitize_bic(bic)
    bic.to_s.gsub(/\s+/, "")
  end

  def bic_suffix
    bic = sanitize_bic(settings.bank_swift)
    bic.present? ? "+#{bic}" : ""
  end

  def format_epc_amount(amount)
    "EUR#{sprintf("%.2f", amount)}"
  end

  def format_spayd_amount(amount)
    sprintf("%.2f", amount)
  end

  def sanitize_spayd_text(text)
    # SPAYD allows alphanumeric, space, and limited punctuation
    # Remove or replace invalid characters
    text.to_s.gsub(/[^A-Za-z0-9 .\-\/]/, "").strip[0, 60]
  end

  def truncate(text, max_length)
    text.to_s[0, max_length]
  end

  def extract_variable_symbol(invoice_number)
    # Extract digits from invoice number for variable symbol
    # e.g., "2024-001" -> "2024001"
    digits = invoice_number.to_s.gsub(/\D/, "")
    digits.present? ? digits[0, 10] : nil
  end

  def generate_qr_svg(payload)
    qrcode = RQRCode::QRCode.new(payload)
    qrcode.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 3,
      standalone: true,
      use_path: true
    )
  end
end
