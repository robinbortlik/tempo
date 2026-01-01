class WorkEntriesController < ApplicationController
  before_action :set_work_entry, only: [:show, :edit, :update, :destroy]

  def index
    entries = filtered_work_entries

    render inertia: "WorkEntries/Index", props: {
      date_groups: entries_grouped_by_date(entries),
      projects: projects_grouped_by_client,
      clients: clients_for_filter,
      filters: current_filters,
      summary: calculate_summary(entries)
    }
  end

  def show
    render inertia: "WorkEntries/Show", props: {
      work_entry: work_entry_json(@work_entry)
    }
  end

  def new
    render inertia: "WorkEntries/New", props: {
      work_entry: empty_work_entry_json,
      projects: projects_grouped_by_client,
      preselected_project_id: params[:project_id]&.to_i
    }
  end

  def edit
    render inertia: "WorkEntries/Edit", props: {
      work_entry: work_entry_json(@work_entry),
      projects: projects_grouped_by_client
    }
  end

  def create
    @work_entry = WorkEntry.new(work_entry_params)

    if @work_entry.save
      redirect_to work_entries_path, notice: "Work entry created successfully."
    else
      redirect_to new_work_entry_path(project_id: params[:work_entry][:project_id]), alert: @work_entry.errors.full_messages.first
    end
  end

  def update
    if @work_entry.invoiced?
      redirect_to work_entries_path, alert: "Cannot update an invoiced work entry."
      return
    end

    if @work_entry.update(work_entry_params)
      redirect_to work_entries_path, notice: "Work entry updated successfully."
    else
      redirect_to edit_work_entry_path(@work_entry), alert: @work_entry.errors.full_messages.first
    end
  end

  def destroy
    if @work_entry.invoiced?
      redirect_to work_entries_path, alert: "Cannot delete an invoiced work entry."
      return
    end

    @work_entry.destroy
    redirect_to work_entries_path, notice: "Work entry deleted successfully."
  end

  def bulk_destroy
    entry_ids = params[:ids] || []
    entries = WorkEntry.where(id: entry_ids).unbilled
    deleted_count = entries.destroy_all.count

    redirect_to work_entries_path, notice: "#{deleted_count} work #{deleted_count == 1 ? 'entry' : 'entries'} deleted successfully."
  end

  private

  def set_work_entry
    @work_entry = WorkEntry.find(params[:id])
  end

  def work_entry_params
    params.require(:work_entry).permit(:project_id, :date, :hours, :amount, :description, :hourly_rate)
  end

  def filtered_work_entries
    entries = WorkEntry.includes(project: :client).order(date: :desc, created_at: :desc)

    if params[:start_date].present? && params[:end_date].present?
      entries = entries.for_date_range(Date.parse(params[:start_date]), Date.parse(params[:end_date]))
    elsif params[:start_date].present?
      entries = entries.where("date >= ?", Date.parse(params[:start_date]))
    elsif params[:end_date].present?
      entries = entries.where("date <= ?", Date.parse(params[:end_date]))
    end

    if params[:client_id].present?
      entries = entries.joins(:project).where(projects: { client_id: params[:client_id] })
    end

    if params[:project_id].present?
      entries = entries.where(project_id: params[:project_id])
    end

    if params[:entry_type].present?
      entries = entries.by_entry_type(params[:entry_type])
    end

    entries
  end

  def calculate_summary(entries)
    time_entries = entries.select(&:time?)
    fixed_entries = entries.select(&:fixed?)

    {
      total_hours: time_entries.sum { |e| e.hours || 0 },
      total_amount: entries.sum { |e| e.calculated_amount || 0 },
      time_entries_count: time_entries.count,
      fixed_entries_count: fixed_entries.count
    }
  end

  def entries_grouped_by_date(entries)
    entries.group_by(&:date).map do |date, date_entries|
      {
        date: date,
        formatted_date: format_date_label(date),
        total_hours: date_entries.select(&:time?).sum { |e| e.hours || 0 },
        total_amount: date_entries.sum { |e| e.calculated_amount || 0 },
        entries: date_entries.map { |entry| work_entry_list_json(entry) }
      }
    end
  end

  def format_date_label(date)
    if date == Date.current
      "Today"
    elsif date == Date.yesterday
      "Yesterday"
    elsif date >= Date.current.beginning_of_week
      date.strftime("%A")
    else
      date.strftime("%B %d, %Y")
    end
  end

  def work_entry_list_json(entry)
    {
      id: entry.id,
      date: entry.date,
      hours: entry.hours,
      amount: entry.amount,
      hourly_rate: entry.hourly_rate,
      entry_type: entry.entry_type,
      description: entry.description,
      status: entry.status,
      calculated_amount: entry.calculated_amount,
      project_id: entry.project_id,
      project_name: entry.project.name,
      client_id: entry.project.client_id,
      client_name: entry.project.client.name,
      client_currency: entry.project.client.currency
    }
  end

  def work_entry_json(entry)
    {
      id: entry.id,
      date: entry.date,
      hours: entry.hours,
      amount: entry.amount,
      hourly_rate: entry.hourly_rate,
      entry_type: entry.entry_type,
      description: entry.description,
      status: entry.status,
      calculated_amount: entry.calculated_amount,
      project_id: entry.project_id,
      project_name: entry.project.name,
      client_id: entry.project.client_id,
      client_name: entry.project.client.name,
      client_currency: entry.project.client.currency,
      effective_hourly_rate: entry.project.effective_hourly_rate,
      invoice_id: entry.invoice_id
    }
  end

  def empty_work_entry_json
    {
      id: nil,
      date: Date.current,
      hours: nil,
      amount: nil,
      entry_type: "time",
      description: "",
      project_id: nil
    }
  end

  def projects_grouped_by_client
    Project.includes(:client).where(active: true).order("clients.name", :name).group_by(&:client).map do |client, client_projects|
      {
        client: {
          id: client.id,
          name: client.name,
          currency: client.currency
        },
        projects: client_projects.map do |project|
          {
            id: project.id,
            name: project.name,
            effective_hourly_rate: project.effective_hourly_rate
          }
        end
      }
    end
  end

  def clients_for_filter
    Client.order(:name).map do |client|
      {
        id: client.id,
        name: client.name
      }
    end
  end

  def current_filters
    {
      start_date: params[:start_date],
      end_date: params[:end_date],
      client_id: params[:client_id]&.to_i,
      project_id: params[:project_id]&.to_i,
      entry_type: params[:entry_type]
    }
  end
end
