class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :toggle_active ]

  def index
    @projects = params[:client_id].present? ? Project.where(client_id: params[:client_id]) : Project.all
    @projects = @projects.includes(:client, :work_entries)
    unbilled_stats = ProjectStatsService.unbilled_hours_for_projects(@projects.map(&:id))

    render inertia: "Projects/Index", props: {
      projects: serialize_projects_grouped_by_client(@projects, unbilled_stats),
      clients: ClientSerializer::ForFilter.new(Client.order(:name)).serializable_hash,
      selected_client_id: params[:client_id]&.to_i
    }
  end

  def show
    work_entries = @project.work_entries.order(date: :desc).limit(50)

    render inertia: "Projects/Show", props: {
      project: ProjectSerializer.new(@project).serializable_hash,
      work_entries: WorkEntrySerializer::ForProjectShow.new(work_entries).serializable_hash,
      stats: ProjectStatsService.new(@project).stats
    }
  end

  def new
    render inertia: "Projects/New", props: {
      project: ProjectSerializer::Empty.serializable_hash,
      clients: ClientSerializer::ForSelect.new(Client.order(:name)).serializable_hash,
      preselected_client_id: params[:client_id]&.to_i
    }
  end

  def edit
    render inertia: "Projects/Edit", props: {
      project: ProjectSerializer.new(@project).serializable_hash,
      clients: ClientSerializer::ForSelect.new(Client.order(:name)).serializable_hash
    }
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to project_path(@project), notice: "Project created successfully."
    else
      redirect_to new_project_path(client_id: params[:project][:client_id]), alert: @project.errors.full_messages.to_sentence
    end
  end

  def update
    if @project.update(project_params)
      redirect_to project_path(@project), notice: "Project updated successfully."
    else
      redirect_to edit_project_path(@project), alert: @project.errors.full_messages.to_sentence
    end
  end

  def destroy
    result = DeletionValidator.can_delete_project?(@project)

    if result[:valid]
      @project.destroy
      redirect_to projects_path, notice: "Project deleted successfully."
    else
      redirect_to project_path(@project), alert: result[:error]
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

  def serialize_projects_grouped_by_client(projects, unbilled_stats)
    projects.group_by(&:client).map do |client, client_projects|
      ProjectSerializer::GroupedByClient.new(
        { client: client, projects: client_projects },
        params: { unbilled_stats: unbilled_stats }
      ).serializable_hash
    end
  end
end
