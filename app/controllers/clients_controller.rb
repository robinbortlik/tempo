class ClientsController < ApplicationController
  before_action :set_client, only: [ :show, :edit, :update, :destroy, :toggle_sharing, :regenerate_share_token ]

  def index
    render inertia: "Clients/Index", props: {
      clients: clients_json
    }
  end

  def show
    render inertia: "Clients/Show", props: {
      client: client_json(@client),
      projects: projects_json(@client),
      recent_work_entries: recent_work_entries_json(@client),
      stats: client_stats(@client)
    }
  end

  def new
    render inertia: "Clients/New", props: {
      client: empty_client_json
    }
  end

  def edit
    render inertia: "Clients/Edit", props: {
      client: client_json(@client)
    }
  end

  def create
    @client = Client.new(client_params)

    if @client.save
      redirect_to client_path(@client), notice: "Client created successfully."
    else
      redirect_to new_client_path, alert: @client.errors.full_messages.first
    end
  end

  def update
    if @client.update(client_params)
      redirect_to client_path(@client), notice: "Client updated successfully."
    else
      redirect_to edit_client_path(@client), alert: @client.errors.full_messages.first
    end
  end

  def destroy
    if @client.projects.exists? || @client.invoices.exists?
      redirect_to client_path(@client), alert: "Cannot delete client with associated projects or invoices."
    else
      @client.destroy
      redirect_to clients_path, notice: "Client deleted successfully."
    end
  end

  def toggle_sharing
    @client.update(sharing_enabled: !@client.sharing_enabled)

    respond_to do |format|
      format.html { redirect_to client_path(@client), notice: "Sharing #{@client.sharing_enabled? ? 'enabled' : 'disabled'} successfully." }
      format.json { render json: { sharing_enabled: @client.sharing_enabled } }
    end
  end

  def regenerate_share_token
    @client.update(share_token: SecureRandom.uuid)

    respond_to do |format|
      format.html { redirect_to client_path(@client), notice: "Share link regenerated successfully." }
      format.json { render json: { share_token: @client.share_token } }
    end
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(
      :name,
      :address,
      :email,
      :contact_person,
      :vat_id,
      :company_registration,
      :bank_details,
      :payment_terms,
      :hourly_rate,
      :currency,
      :default_vat_rate
    )
  end

  def clients_json
    Client.includes(:projects).map do |client|
      {
        id: client.id,
        name: client.name,
        email: client.email,
        currency: client.currency,
        hourly_rate: client.hourly_rate,
        unbilled_hours: unbilled_hours_for(client),
        unbilled_amount: unbilled_amount_for(client),
        projects_count: client.projects.size
      }
    end
  end

  def client_json(client)
    {
      id: client.id,
      name: client.name,
      address: client.address,
      email: client.email,
      contact_person: client.contact_person,
      vat_id: client.vat_id,
      company_registration: client.company_registration,
      bank_details: client.bank_details,
      payment_terms: client.payment_terms,
      hourly_rate: client.hourly_rate,
      currency: client.currency,
      default_vat_rate: client.default_vat_rate,
      share_token: client.share_token,
      sharing_enabled: client.sharing_enabled
    }
  end

  def empty_client_json
    {
      id: nil,
      name: "",
      address: "",
      email: "",
      contact_person: "",
      vat_id: "",
      company_registration: "",
      bank_details: "",
      payment_terms: "",
      hourly_rate: nil,
      currency: "",
      default_vat_rate: nil
    }
  end

  def projects_json(client)
    client.projects.map do |project|
      {
        id: project.id,
        name: project.name,
        hourly_rate: project.hourly_rate,
        effective_hourly_rate: project.effective_hourly_rate,
        active: project.active,
        unbilled_hours: project.work_entries.time.unbilled.sum(:hours)
      }
    end
  end

  def recent_work_entries_json(client)
    WorkEntry.joins(:project)
             .where(projects: { client_id: client.id })
             .order(date: :desc)
             .limit(10)
             .includes(project: :client)
             .map do |entry|
      {
        id: entry.id,
        date: entry.date,
        hours: entry.hours,
        amount: entry.amount,
        entry_type: entry.entry_type,
        description: entry.description,
        status: entry.status,
        project_name: entry.project.name,
        calculated_amount: entry.calculated_amount
      }
    end
  end

  def client_stats(client)
    work_entries = WorkEntry.joins(:project).where(projects: { client_id: client.id })
    unbilled_entries = work_entries.unbilled

    {
      total_hours: work_entries.time.sum(:hours),
      total_invoiced: client.invoices.final.sum(:total_amount),
      unbilled_hours: unbilled_entries.time.sum(:hours),
      unbilled_amount: unbilled_entries.includes(project: :client).sum { |e| e.calculated_amount || 0 }
    }
  end

  def unbilled_hours_for(client)
    WorkEntry.time.joins(:project)
             .where(projects: { client_id: client.id })
             .unbilled
             .sum(:hours)
  end

  def unbilled_amount_for(client)
    WorkEntry.joins(:project)
             .where(projects: { client_id: client.id })
             .unbilled
             .includes(project: :client)
             .sum { |entry| entry.calculated_amount || 0 }
  end
end
