# Calculates dashboard statistics for hours and unbilled amounts
class DashboardStatsService
  def stats
    {
      hours_this_week: hours_this_week,
      hours_this_month: hours_this_month,
      unbilled_hours: unbilled_hours,
      unbilled_amounts: unbilled_amounts_by_currency,
      unbilled_by_client: unbilled_by_client
    }
  end

  def hours_this_week
    TimeEntry.for_date_range(Date.current.beginning_of_week, Date.current.end_of_week).sum(:hours).to_f
  end

  def hours_this_month
    TimeEntry.for_date_range(Date.current.beginning_of_month, Date.current.end_of_month).sum(:hours).to_f
  end

  def unbilled_hours
    TimeEntry.unbilled.sum(:hours).to_f
  end

  def unbilled_amounts_by_currency
    # Group unbilled time entries by client currency and sum amounts
    unbilled_entries_with_amounts.each_with_object(Hash.new(0.0)) do |entry, totals|
      currency = entry.project.client.currency || "EUR"
      totals[currency] += entry.calculated_amount || 0
    end
  end

  def unbilled_by_client
    clients_with_unbilled_entries.map do |client|
      entries = unbilled_entries_for_client(client)
      projects_with_unbilled = entries.map(&:project).uniq

      total_hours = entries.sum(&:hours)
      total_amount = entries.sum { |e| e.calculated_amount || 0 }

      {
        id: client.id,
        name: client.name,
        currency: client.currency || "EUR",
        project_count: projects_with_unbilled.count,
        total_hours: total_hours.to_f,
        total_amount: total_amount.to_f,
        average_rate: total_hours > 0 ? (total_amount / total_hours).round(2) : 0
      }
    end.sort_by { |c| -c[:total_amount] }
  end

  # Chart data methods
  def time_by_client
    # Group all time entries by client for pie chart
    TimeEntry
      .joins(project: :client)
      .group("clients.id", "clients.name")
      .sum(:hours)
      .map { |(id, name), hours| { id: id, name: name, hours: hours.to_f } }
      .sort_by { |c| -c[:hours] }
  end

  def time_by_project
    # Group all time entries by project for bar chart
    TimeEntry
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

    TimeEntry
      .where("date >= ?", start_date)
      .group_by { |entry| entry.date.beginning_of_month }
      .transform_values { |entries| entries.sum(&:hours).to_f }
      .then { |data| fill_missing_months(data, months) }
      .map { |month, hours| { month: month.strftime("%b %Y"), hours: hours } }
  end

  private

  def unbilled_entries_with_amounts
    @unbilled_entries_with_amounts ||= TimeEntry
      .unbilled
      .includes(project: :client)
  end

  def clients_with_unbilled_entries
    @clients_with_unbilled_entries ||= Client
      .joins(projects: :time_entries)
      .where(time_entries: { status: :unbilled })
      .distinct
  end

  def unbilled_entries_for_client(client)
    TimeEntry
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
