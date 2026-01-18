# Calculates dashboard statistics for hours and unbilled amounts
class DashboardStatsService
  def stats
    {
      hours_this_week: hours_this_week,
      hours_this_month: hours_this_month,
      unbilled_hours: unbilled_hours,
      unbilled_amounts: unbilled_amounts_by_currency,
      unbilled_by_client: unbilled_by_client,
      total_in_main_currency: total_in_main_currency
    }
  end

  def hours_this_week
    WorkEntry.time.for_date_range(Date.current.beginning_of_week, Date.current.end_of_week).sum(:hours).to_f
  end

  def hours_this_month
    WorkEntry.time.for_date_range(Date.current.beginning_of_month, Date.current.end_of_month).sum(:hours).to_f
  end

  def unbilled_hours
    WorkEntry.time.unbilled.sum(:hours).to_f
  end

  def unbilled_amounts_by_currency
    # Group unbilled work entries by client currency and sum amounts
    unbilled_entries_with_amounts.each_with_object(Hash.new(0.0)) do |entry, totals|
      currency = entry.project.client.currency || "EUR"
      totals[currency] += entry.calculated_amount || 0
    end
  end

  def unbilled_by_client
    clients_with_unbilled_entries.map do |client|
      entries = unbilled_entries_for_client(client)
      projects_with_unbilled = entries.map(&:project).uniq

      total_hours = entries.select(&:time?).sum { |e| e.hours || 0 }
      total_amount = entries.sum { |e| e.calculated_amount || 0 }

      # Get unique effective hourly rates from projects with unbilled time entries
      project_rates = projects_with_unbilled
        .map(&:effective_hourly_rate)
        .compact
        .uniq
        .sort

      {
        id: client.id,
        name: client.name,
        currency: client.currency || "EUR",
        project_count: projects_with_unbilled.count,
        total_hours: total_hours.to_f,
        total_amount: total_amount.to_f,
        project_rates: project_rates
      }
    end.sort_by { |c| -c[:total_amount] }
  end

  # Chart data methods
  def time_by_client
    # Group all work entries by client for pie chart
    WorkEntry
      .time
      .joins(project: :client)
      .group("clients.id", "clients.name")
      .sum(:hours)
      .map { |(id, name), hours| { id: id, name: name, hours: hours.to_f } }
      .sort_by { |c| -c[:hours] }
  end

  def time_by_project
    # Group all work entries by project for bar chart
    WorkEntry
      .time
      .joins(:project)
      .group("projects.id", "projects.name")
      .sum(:hours)
      .map { |(id, name), hours| { id: id, name: name, hours: hours.to_f } }
      .sort_by { |p| -p[:hours] }
      .first(10) # Top 10 projects
  end

  def earnings_over_time(months: 12)
    # Monthly earnings from finalized invoices for line chart
    start_date = months.months.ago.beginning_of_month

    Invoice
      .final
      .where("issue_date >= ?", start_date)
      .group_by { |invoice| invoice.issue_date.beginning_of_month }
      .transform_values { |invoices| invoices.sum(&:total_amount).to_f }
      .then { |data| fill_missing_months(data, months) }
      .map { |month, amount| { month: month.strftime("%b %Y"), amount: amount } }
  end

  def hours_trend(months: 12)
    # Monthly hours logged for trend chart
    start_date = months.months.ago.beginning_of_month

    WorkEntry
      .time
      .where("date >= ?", start_date)
      .group_by { |entry| entry.date.beginning_of_month }
      .transform_values { |entries| entries.sum { |e| e.hours || 0 }.to_f }
      .then { |data| fill_missing_months(data, months) }
      .map { |month, hours| { month: month.strftime("%b %Y"), hours: hours } }
  end

  def total_in_main_currency
    invoices = paid_invoices_current_year
    return { amount: 0.0, missing_exchange_rates: false } if invoices.empty?

    total = 0.0
    missing_rates = false

    invoices.each do |invoice|
      converted_amount = invoice.main_currency_amount
      if converted_amount.nil?
        missing_rates = true
      else
        total += converted_amount
      end
    end

    { amount: total, missing_exchange_rates: missing_rates }
  end

  private

  def paid_invoices_current_year
    @paid_invoices_current_year ||= Invoice
      .paid
      .for_year(Date.current.year)
  end

  def unbilled_entries_with_amounts
    @unbilled_entries_with_amounts ||= WorkEntry
      .unbilled
      .includes(project: :client)
  end

  def clients_with_unbilled_entries
    @clients_with_unbilled_entries ||= Client
      .joins(projects: :work_entries)
      .where(work_entries: { status: :unbilled })
      .distinct
  end

  def unbilled_entries_for_client(client)
    WorkEntry
      .unbilled
      .joins(:project)
      .where(projects: { client_id: client.id })
      .includes(project: :client)
  end

  def fill_missing_months(data, months)
    result = {}
    months.times do |i|
      month = (months - 1 - i).months.ago.beginning_of_month.to_date
      result[month] = data[month] || 0
    end
    result
  end
end
