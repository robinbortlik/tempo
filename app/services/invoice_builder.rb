# Builds invoice preview data and creates draft invoices from unbilled work entries
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
      line_items: build_line_items_preview,
      project_groups: project_groups,
      total_hours: total_hours,
      total_amount: total_amount,
      currency: client.currency,
      time_entry_ids: unbilled_entries.map(&:id),
      work_entry_ids: unbilled_entries.map(&:id)
    }
  end

  # Creates a draft invoice and associates the work entries via line items
  def create_draft
    return { success: false, errors: ["No unbilled work entries found for the specified period"] } if unbilled_entries.empty?

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
      create_line_items(invoice)
      invoice.calculate_totals!
    end

    { success: true, invoice: invoice }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  # Returns unbilled work entries for the client within the date range
  def unbilled_entries
    @unbilled_entries ||= WorkEntry
      .joins(:project)
      .where(projects: { client_id: client.id })
      .where(status: :unbilled)
      .for_date_range(period_start, period_end)
      .includes(project: :client)
      .order(date: :asc)
  end

  def total_hours
    time_entries.sum { |e| e.hours || 0 }
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

  # Entries that are time-based (have hours)
  def time_entries
    unbilled_entries.select(&:time?)
  end

  # Entries that are fixed-price (no hours)
  def fixed_entries
    unbilled_entries.select(&:fixed?)
  end

  # Build line items preview data structure
  def build_line_items_preview
    items = []
    position = 0

    # Group time entries by project and create aggregate line items
    time_entries.group_by(&:project).each do |project, entries|
      total_hours_for_project = entries.sum { |e| e.hours || 0 }
      rate = project.effective_hourly_rate || 0
      total_for_project = entries.sum { |e| e.calculated_amount || 0 }

      items << {
        line_type: "time_aggregate",
        description: "#{project.name} - #{format_hours(total_hours_for_project)}h @ #{format_currency(rate)}/h",
        quantity: total_hours_for_project,
        unit_price: rate,
        amount: total_for_project,
        position: position,
        project_id: project.id,
        project_name: project.name,
        work_entry_ids: entries.map(&:id)
      }
      position += 1
    end

    # Add individual fixed entries
    fixed_entries.each do |entry|
      items << {
        line_type: "fixed",
        description: entry.description || "Fixed-price item",
        quantity: nil,
        unit_price: nil,
        amount: entry.amount || 0,
        position: position,
        project_id: entry.project_id,
        project_name: entry.project.name,
        work_entry_ids: [entry.id]
      }
      position += 1
    end

    items
  end

  # Create actual InvoiceLineItem records and link work entries
  def create_line_items(invoice)
    position = 0

    # Group time entries by project and create aggregate line items
    time_entries.group_by(&:project).each do |project, entries|
      total_hours_for_project = entries.sum { |e| e.hours || 0 }
      rate = project.effective_hourly_rate || 0
      total_for_project = entries.sum { |e| e.calculated_amount || 0 }

      line_item = invoice.line_items.create!(
        line_type: :time_aggregate,
        description: "#{project.name} - #{format_hours(total_hours_for_project)}h @ #{format_currency(rate)}/h",
        quantity: total_hours_for_project,
        unit_price: rate,
        amount: total_for_project,
        position: position
      )

      # Link work entries to line item and mark as invoiced
      entries.each do |entry|
        InvoiceLineItemWorkEntry.create!(invoice_line_item: line_item, work_entry: entry)
        entry.update!(invoice: invoice, status: :invoiced)
      end

      position += 1
    end

    # Add individual fixed entries
    fixed_entries.each do |entry|
      line_item = invoice.line_items.create!(
        line_type: :fixed,
        description: entry.description || "Fixed-price item",
        quantity: nil,
        unit_price: nil,
        amount: entry.amount || 0,
        position: position
      )

      # Link work entry to line item and mark as invoiced
      InvoiceLineItemWorkEntry.create!(invoice_line_item: line_item, work_entry: entry)
      entry.update!(invoice: invoice, status: :invoiced)

      position += 1
    end
  end

  def format_hours(hours)
    hours % 1 == 0 ? hours.to_i.to_s : format("%.1f", hours)
  end

  def format_currency(amount)
    format("%.2f", amount)
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
        total_hours: entries.sum { |e| e.hours || 0 },
        total_amount: entries.sum { |e| e.calculated_amount || 0 }
      }
    end
  end

  def entry_data(entry)
    {
      id: entry.id,
      date: entry.date,
      hours: entry.hours,
      amount: entry.amount,
      entry_type: entry.entry_type,
      description: entry.description,
      calculated_amount: entry.calculated_amount
    }
  end
end
