class ClientStatsService
  def initialize(client)
    @client = client
  end

  def stats
    {
      total_hours: total_hours,
      total_invoiced: total_invoiced,
      unbilled_hours: unbilled_hours,
      unbilled_amount: unbilled_amount
    }
  end

  # Preloads unbilled stats for multiple clients to avoid N+1 queries
  # Returns a hash: { client_id => { hours: X, amount: Y } }
  def self.unbilled_stats_for_clients(client_ids)
    return {} if client_ids.empty?

    hours_by_client = WorkEntry.time
      .joins(:project)
      .where(projects: { client_id: client_ids })
      .unbilled
      .group("projects.client_id")
      .sum(:hours)

    amounts_by_client = calculate_unbilled_amounts_by_client(client_ids)

    client_ids.index_with do |client_id|
      {
        hours: hours_by_client[client_id] || 0,
        amount: amounts_by_client[client_id] || 0
      }
    end
  end

  # Preloads unbilled entry counts for multiple clients
  # Returns a hash: { client_id => count }
  def self.unbilled_counts_for_clients(client_ids)
    return {} if client_ids.empty?

    WorkEntry.joins(:project)
      .where(projects: { client_id: client_ids })
      .unbilled
      .group("projects.client_id")
      .count
  end

  private

  def work_entries
    @work_entries ||= WorkEntry.joins(:project).where(projects: { client_id: @client.id })
  end

  def unbilled_entries
    @unbilled_entries ||= work_entries.unbilled
  end

  def total_hours
    work_entries.time.sum(:hours)
  end

  def total_invoiced
    @client.invoices.final.sum(:total_amount)
  end

  def unbilled_hours
    unbilled_entries.time.sum(:hours)
  end

  def unbilled_amount
    unbilled_entries.includes(project: :client).sum { |e| e.calculated_amount || 0 }
  end

  def self.calculate_unbilled_amounts_by_client(client_ids)
    WorkEntry.joins(:project)
      .where(projects: { client_id: client_ids })
      .unbilled
      .includes(project: :client)
      .group_by { |e| e.project.client_id }
      .transform_values { |entries| entries.sum { |e| e.calculated_amount || 0 } }
  end
end
