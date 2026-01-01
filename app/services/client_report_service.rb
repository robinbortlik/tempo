# Generates report data for a client's work entries, grouped by project
# Used for the public client report portal accessible via share_token
class ClientReportService
  attr_reader :client, :year, :month

  def initialize(client:, year: nil, month: nil)
    @client = client
    @year = (year || Date.current.year).to_i
    @month = month&.to_i # nil means all months in the year
  end

  # Returns the complete report data structure
  def report
    {
      client: client_data,
      period: period_data,
      unbilled: unbilled_data,
      invoiced: invoiced_data
    }
  end

  # Returns unbilled entries for the period, grouped by project
  def unbilled_entries
    @unbilled_entries ||= fetch_entries(:unbilled)
  end

  # Returns invoiced entries for the period, grouped by project
  def invoiced_entries
    @invoiced_entries ||= fetch_entries(:invoiced)
  end

  # Returns unbilled section data with project groups and totals
  def unbilled_data
    {
      project_groups: build_project_groups(unbilled_entries),
      total_hours: unbilled_entries.select(&:time?).sum { |e| e.hours || 0 },
      total_amount: unbilled_entries.sum { |e| e.calculated_amount || 0 }
    }
  end

  # Returns invoiced section data with project groups, totals, and invoice summaries
  def invoiced_data
    {
      project_groups: build_project_groups(invoiced_entries),
      total_hours: invoiced_entries.select(&:time?).sum { |e| e.hours || 0 },
      total_amount: invoiced_entries.sum { |e| e.calculated_amount || 0 },
      invoices: invoices_in_period
    }
  end

  private

  def fetch_entries(status)
    WorkEntry
      .joins(:project)
      .where(projects: { client_id: client.id })
      .where(status: status)
      .for_date_range(period_start, period_end)
      .includes(project: :client)
      .order(date: :desc)
  end

  def build_project_groups(entries)
    entries.group_by(&:project).map do |project, project_entries|
      {
        project: {
          id: project.id,
          name: project.name,
          effective_hourly_rate: project.effective_hourly_rate
        },
        entries: project_entries.map { |entry| entry_data(entry) },
        total_hours: project_entries.select(&:time?).sum { |e| e.hours || 0 },
        total_amount: project_entries.sum { |e| e.calculated_amount || 0 }
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

  def invoices_in_period
    Invoice
      .where(client: client)
      .where(status: :final)
      .where("(period_start <= ? AND period_end >= ?) OR (period_start >= ? AND period_start <= ?)",
             period_end, period_start, period_start, period_end)
      .includes(line_items: { work_entries: :project })
      .order(issue_date: :desc)
      .map do |invoice|
        {
          id: invoice.id,
          number: invoice.number,
          issue_date: invoice.issue_date,
          period_start: invoice.period_start,
          period_end: invoice.period_end,
          total_hours: invoice.total_hours,
          total_amount: invoice.total_amount,
          subtotal: invoice.subtotal,
          total_vat: invoice.total_vat,
          line_items: invoice.line_items.map { |item| line_item_data(item) }
        }
      end
  end

  def line_item_data(item)
    {
      id: item.id,
      line_type: item.line_type,
      description: item.description,
      quantity: item.quantity,
      unit_price: item.unit_price,
      amount: item.amount,
      vat_rate: item.vat_rate,
      work_entries: item.work_entries.order(date: :desc).map { |entry| line_item_entry_data(entry) }
    }
  end

  def line_item_entry_data(entry)
    {
      id: entry.id,
      date: entry.date,
      hours: entry.hours,
      description: entry.description,
      calculated_amount: entry.calculated_amount,
      entry_type: entry.entry_type,
      project_name: entry.project.name
    }
  end

  def client_data
    {
      id: client.id,
      name: client.name,
      currency: client.currency
    }
  end

  def period_data
    {
      year: year,
      month: month,
      available_years: available_years
    }
  end

  def available_years
    # Get years that have any work entries for this client
    years_with_entries = WorkEntry
      .joins(:project)
      .where(projects: { client_id: client.id })
      .distinct
      .pluck(Arel.sql("strftime('%Y', date)"))
      .map(&:to_i)

    # Always include current year
    (years_with_entries + [Date.current.year]).uniq.sort.reverse
  end

  def period_start
    if month
      Date.new(year, month, 1)
    else
      Date.new(year, 1, 1)
    end
  end

  def period_end
    if month
      Date.new(year, month, 1).end_of_month
    else
      Date.new(year, 12, 31)
    end
  end
end
