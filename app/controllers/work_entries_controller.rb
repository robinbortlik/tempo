class WorkEntriesController < ApplicationController
  before_action :set_work_entry, only: [ :update, :destroy ]

  def index
    filter_service = WorkEntryFilterService.new(params: filter_params)
    entries = filter_service.filter

    render inertia: "WorkEntries/Index", props: {
      date_groups: serialize_entries_grouped_by_date(entries),
      projects: serialize_projects_for_form,
      clients: ClientSerializer::ForFilter.new(Client.order(:name)).serializable_hash,
      filters: current_filters,
      period: {
        year: filter_service.year,
        month: filter_service.month,
        available_years: filter_service.available_years
      },
      summary: filter_service.summary
    }
  end

  def create
    @work_entry = WorkEntry.new(work_entry_params)

    if @work_entry.save
      redirect_to work_entries_path, notice: "Work entry created successfully."
    else
      redirect_to work_entries_path, alert: @work_entry.errors.full_messages.to_sentence
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
      redirect_to work_entries_path, alert: @work_entry.errors.full_messages.to_sentence
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

  def filter_params
    {
      year: params[:year],
      month: params[:month],
      client_id: params[:client_id],
      project_id: params[:project_id],
      entry_type: params[:entry_type]
    }
  end

  def serialize_entries_grouped_by_date(entries)
    entries.group_by(&:date).map do |date, date_entries|
      WorkEntrySerializer::GroupedByDate.new({
        date: date,
        formatted_date: format_date_label(date),
        entries: date_entries
      }).serializable_hash
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

  def serialize_projects_for_form
    Project.includes(:client).where(active: true).order("clients.name", :name)
           .group_by(&:client).map do |client, client_projects|
      ProjectSerializer::GroupedByClientForForm.new({
        client: client,
        projects: client_projects
      }).serializable_hash
    end
  end

  def current_filters
    {
      client_id: params[:client_id]&.to_i,
      project_id: params[:project_id]&.to_i,
      entry_type: params[:entry_type]
    }
  end
end
