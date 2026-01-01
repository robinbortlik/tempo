class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :toggle_active ]

  def index
    @projects = params[:client_id].present? ? Project.where(client_id: params[:client_id]) : Project.all
    @projects = @projects.includes(:client, :work_entries)

    render inertia: "Projects/Index", props: {
      projects: projects_grouped_by_client(@projects),
      clients: clients_for_filter,
      selected_client_id: params[:client_id]&.to_i
    }
  end

  def show
    render inertia: "Projects/Show", props: {
      project: project_json(@project),
      work_entries: work_entries_json(@project),
      stats: project_stats(@project)
    }
  end

  def new
    render inertia: "Projects/New", props: {
      project: empty_project_json,
      clients: clients_for_select,
      preselected_client_id: params[:client_id]&.to_i
    }
  end

  def edit
    render inertia: "Projects/Edit", props: {
      project: project_json(@project),
      clients: clients_for_select
    }
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to project_path(@project), notice: "Project created successfully."
    else
      redirect_to new_project_path(client_id: params[:project][:client_id]), alert: @project.errors.full_messages.first
    end
  end

  def update
    if @project.update(project_params)
      redirect_to project_path(@project), notice: "Project updated successfully."
    else
      redirect_to edit_project_path(@project), alert: @project.errors.full_messages.first
    end
  end

  def destroy
    if @project.work_entries.invoiced.exists?
      redirect_to project_path(@project), alert: "Cannot delete project with invoiced work entries."
    else
      @project.destroy
      redirect_to projects_path, notice: "Project deleted successfully."
    end
  end

  def toggle_active
    @project.update(active: !@project.active)
    redirect_to project_path(@project), notice: "Project #{@project.active? ? 'activated' : 'deactivated'} successfully."
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :client_id, :hourly_rate, :active)
  end

  def projects_grouped_by_client(projects)
    projects.group_by(&:client).map do |client, client_projects|
      {
        client: {
          id: client.id,
          name: client.name,
          currency: client.currency
        },
        projects: client_projects.map { |project| project_list_json(project) }
      }
    end
  end

  def project_list_json(project)
    {
      id: project.id,
      name: project.name,
      hourly_rate: project.hourly_rate,
      effective_hourly_rate: project.effective_hourly_rate,
      active: project.active,
      unbilled_hours: project.work_entries.unbilled.sum(:hours),
      work_entries_count: project.work_entries.size
    }
  end

  def project_json(project)
    {
      id: project.id,
      name: project.name,
      client_id: project.client_id,
      client_name: project.client.name,
      client_currency: project.client.currency,
      hourly_rate: project.hourly_rate,
      effective_hourly_rate: project.effective_hourly_rate,
      active: project.active
    }
  end

  def empty_project_json
    {
      id: nil,
      name: "",
      client_id: nil,
      hourly_rate: nil,
      active: true
    }
  end

  def work_entries_json(project)
    project.work_entries
           .order(date: :desc)
           .limit(50)
           .map do |entry|
      {
        id: entry.id,
        date: entry.date,
        hours: entry.hours,
        description: entry.description,
        status: entry.status,
        calculated_amount: entry.calculated_amount.to_f
      }
    end
  end

  def project_stats(project)
    work_entries = project.work_entries
    unbilled_entries = work_entries.unbilled

    {
      total_hours: work_entries.sum(:hours),
      unbilled_hours: unbilled_entries.sum(:hours),
      unbilled_amount: unbilled_entries.sum { |e| e.calculated_amount || 0 }.to_f
    }
  end

  def clients_for_filter
    Client.order(:name).map do |client|
      {
        id: client.id,
        name: client.name
      }
    end
  end

  def clients_for_select
    Client.order(:name).map do |client|
      {
        id: client.id,
        name: client.name,
        hourly_rate: client.hourly_rate,
        currency: client.currency
      }
    end
  end
end
