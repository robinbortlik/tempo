class TimeEntriesController < ApplicationController
  before_action :set_time_entry, only: [:show, :edit, :update, :destroy]

  def index
    entries = filtered_time_entries

    render inertia: "TimeEntries/Index", props: {
      date_groups: entries_grouped_by_date(entries),
      projects: projects_grouped_by_client,
      clients: clients_for_filter,
      filters: current_filters
    }
  end

  def show
    render inertia: "TimeEntries/Show", props: {
      time_entry: time_entry_json(@time_entry)
    }
  end

  def new
    render inertia: "TimeEntries/New", props: {
      time_entry: empty_time_entry_json,
      projects: projects_grouped_by_client,
      preselected_project_id: params[:project_id]&.to_i
    }
  end

  def edit
    render inertia: "TimeEntries/Edit", props: {
      time_entry: time_entry_json(@time_entry),
      projects: projects_grouped_by_client
    }
  end

  def create
    @time_entry = TimeEntry.new(time_entry_params)

    if @time_entry.save
      redirect_to time_entries_path, notice: "Time entry created successfully."
    else
      redirect_to new_time_entry_path(project_id: params[:time_entry][:project_id]), alert: @time_entry.errors.full_messages.first
    end
  end

  def update
    if @time_entry.invoiced?
      redirect_to time_entries_path, alert: "Cannot update an invoiced time entry."
      return
    end

    if @time_entry.update(time_entry_params)
      redirect_to time_entries_path, notice: "Time entry updated successfully."
    else
      redirect_to edit_time_entry_path(@time_entry), alert: @time_entry.errors.full_messages.first
    end
  end

  def destroy
    if @time_entry.invoiced?
      redirect_to time_entries_path, alert: "Cannot delete an invoiced time entry."
      return
    end

    @time_entry.destroy
    redirect_to time_entries_path, notice: "Time entry deleted successfully."
  end

  def bulk_destroy
    entry_ids = params[:ids] || []
    entries = TimeEntry.where(id: entry_ids).unbilled
    deleted_count = entries.destroy_all.count

    redirect_to time_entries_path, notice: "#{deleted_count} time #{deleted_count == 1 ? 'entry' : 'entries'} deleted successfully."
  end

  private

  def set_time_entry
    @time_entry = TimeEntry.find(params[:id])
  end

  def time_entry_params
    params.require(:time_entry).permit(:project_id, :date, :hours, :description)
  end

  def filtered_time_entries
    entries = TimeEntry.includes(project: :client).order(date: :desc, created_at: :desc)

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

    entries
  end

  def entries_grouped_by_date(entries)
    entries.group_by(&:date).map do |date, date_entries|
      {
        date: date,
        formatted_date: format_date_label(date),
        total_hours: date_entries.sum(&:hours),
        entries: date_entries.map { |entry| time_entry_list_json(entry) }
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

  def time_entry_list_json(entry)
    {
      id: entry.id,
      date: entry.date,
      hours: entry.hours,
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

  def time_entry_json(entry)
    {
      id: entry.id,
      date: entry.date,
      hours: entry.hours,
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

  def empty_time_entry_json
    {
      id: nil,
      date: Date.current,
      hours: nil,
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
      project_id: params[:project_id]&.to_i
    }
  end
end
