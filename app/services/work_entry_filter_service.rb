class WorkEntryFilterService
  def initialize(scope: WorkEntry.all, params: {})
    @scope = scope
    @params = params
  end

  def filter
    @scope = @scope.includes(project: :client).order(date: :desc, created_at: :desc)
    @scope = filter_by_date_range
    @scope = filter_by_client
    @scope = filter_by_project
    @scope = filter_by_entry_type
    @scope
  end

  def summary
    entries = filter.to_a
    time_entries = entries.select(&:time?)
    fixed_entries = entries.select(&:fixed?)

    {
      total_hours: time_entries.sum { |e| e.hours || 0 },
      total_amount: entries.sum { |e| e.calculated_amount || 0 },
      time_entries_count: time_entries.count,
      fixed_entries_count: fixed_entries.count
    }
  end

  private

  def filter_by_date_range
    return @scope unless @params[:start_date].present? || @params[:end_date].present?

    if @params[:start_date].present? && @params[:end_date].present?
      @scope.for_date_range(parse_date(@params[:start_date]), parse_date(@params[:end_date]))
    elsif @params[:start_date].present?
      @scope.where("date >= ?", parse_date(@params[:start_date]))
    else
      @scope.where("date <= ?", parse_date(@params[:end_date]))
    end
  end

  def filter_by_client
    return @scope unless @params[:client_id].present?

    @scope.joins(:project).where(projects: { client_id: @params[:client_id] })
  end

  def filter_by_project
    return @scope unless @params[:project_id].present?

    @scope.where(project_id: @params[:project_id])
  end

  def filter_by_entry_type
    return @scope unless @params[:entry_type].present?

    @scope.by_entry_type(@params[:entry_type])
  end

  def parse_date(value)
    value.is_a?(String) ? Date.parse(value) : value
  end
end
