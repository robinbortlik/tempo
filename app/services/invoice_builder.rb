# Builds invoice preview data and creates draft invoices from unbilled time entries
class InvoiceBuilder
  attr_reader :client, :period_start, :period_end, :issue_date, :due_date, :notes

  def initialize(client_id:, period_start:, period_end:, issue_date: nil, due_date: nil, notes: nil)
    @client = Client.find(client_id)
    @period_start = period_start.is_a?(String) ? Date.parse(period_start) : period_start
    @period_end = period_end.is_a?(String) ? Date.parse(period_end) : period_end
    @issue_date = issue_date.is_a?(String) ? Date.parse(issue_date) : (issue_date || Date.current)
    @due_date = due_date.is_a?(String) ? Date.parse(due_date) : (due_date || calculate_default_due_date)
    @notes = notes
  end

  # Returns preview data for the new invoice page (without creating the invoice)
  def preview
    {
      client: client_data,
      period_start: period_start,
      period_end: period_end,
      issue_date: issue_date,
      due_date: due_date,
      project_groups: project_groups,
      total_hours: total_hours,
      total_amount: total_amount,
      currency: client.currency,
      time_entry_ids: unbilled_entries.map(&:id)
    }
  end

  # Creates a draft invoice and associates the time entries
  def create_draft
    return { success: false, errors: ["No unbilled time entries found for the specified period"] } if unbilled_entries.empty?

    invoice = Invoice.new(
      client: client,
      status: :draft,
      issue_date: issue_date,
      due_date: due_date,
      period_start: period_start,
      period_end: period_end,
      currency: client.currency,
      notes: notes
    )

    Invoice.transaction do
      invoice.save!
      unbilled_entries.update_all(invoice_id: invoice.id)
      invoice.calculate_totals!
    end

    { success: true, invoice: invoice }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  # Returns unbilled time entries for the client within the date range
  def unbilled_entries
    @unbilled_entries ||= TimeEntry
      .joins(:project)
      .where(projects: { client_id: client.id })
      .where(status: :unbilled)
      .for_date_range(period_start, period_end)
      .includes(project: :client)
      .order(date: :asc)
  end

  def total_hours
    unbilled_entries.sum(&:hours)
  end

  def total_amount
    unbilled_entries.sum { |entry| entry.calculated_amount || 0 }
  end

  private

  def calculate_default_due_date
    # Default to 30 days from issue date, or use client's payment terms if available
    payment_days = parse_payment_terms(client.payment_terms) || 30
    (issue_date || Date.current) + payment_days.days
  end

  def parse_payment_terms(terms)
    return nil unless terms.present?
    # Try to extract number from common formats like "Net 30", "Net 30 days", "30 days"
    match = terms.match(/(\d+)/)
    match ? match[1].to_i : nil
  end

  def client_data
    {
      id: client.id,
      name: client.name,
      address: client.address,
      email: client.email,
      vat_id: client.vat_id,
      currency: client.currency,
      hourly_rate: client.hourly_rate
    }
  end

  def project_groups
    unbilled_entries.group_by(&:project).map do |project, entries|
      {
        project: {
          id: project.id,
          name: project.name,
          effective_hourly_rate: project.effective_hourly_rate
        },
        entries: entries.map { |entry| entry_data(entry) },
        total_hours: entries.sum(&:hours),
        total_amount: entries.sum { |e| e.calculated_amount || 0 }
      }
    end
  end

  def entry_data(entry)
    {
      id: entry.id,
      date: entry.date,
      hours: entry.hours,
      description: entry.description,
      calculated_amount: entry.calculated_amount
    }
  end
end
