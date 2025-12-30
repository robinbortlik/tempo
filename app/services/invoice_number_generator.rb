# Generates sequential invoice numbers in YYYY-NNN format
# Example: 2024-001, 2024-002, 2025-001
class InvoiceNumberGenerator
  def self.generate(year: nil)
    new(year: year).generate
  end

  def initialize(year: nil)
    @year = year || Date.current.year
  end

  def generate
    "#{@year}-#{formatted_sequence_number}"
  end

  private

  def formatted_sequence_number
    next_sequence_number.to_s.rjust(3, "0")
  end

  def next_sequence_number
    last_sequence_for_year + 1
  end

  def last_sequence_for_year
    last_invoice = Invoice.where("number LIKE ?", "#{@year}-%")
                          .order(number: :desc)
                          .first

    return 0 unless last_invoice

    # Extract the sequence number from YYYY-NNN format
    last_invoice.number.split("-").last.to_i
  end
end
