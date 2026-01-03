class ProjectStatsService
  def initialize(project)
    @project = project
  end

  def stats
    {
      total_hours: total_hours,
      unbilled_hours: unbilled_hours,
      unbilled_amount: unbilled_amount
    }
  end

  # Preloads unbilled hours for multiple projects to avoid N+1 queries
  # Returns a hash: { project_id => hours }
  def self.unbilled_hours_for_projects(project_ids)
    return {} if project_ids.empty?

    WorkEntry.where(project_id: project_ids)
      .unbilled
      .group(:project_id)
      .sum(:hours)
  end

  private

  def work_entries
    @work_entries ||= @project.work_entries
  end

  def unbilled_entries
    @unbilled_entries ||= work_entries.unbilled
  end

  def total_hours
    work_entries.sum(:hours)
  end

  def unbilled_hours
    unbilled_entries.sum(:hours)
  end

  def unbilled_amount
    unbilled_entries.sum { |e| e.calculated_amount || 0 }.to_f
  end
end
