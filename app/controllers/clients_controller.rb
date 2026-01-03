class ClientsController < ApplicationController
  before_action :set_client, only: [ :show, :edit, :update, :destroy, :toggle_sharing, :regenerate_share_token ]

  def index
    clients = Client.includes(:projects).to_a
    unbilled_stats = ClientStatsService.unbilled_stats_for_clients(clients.map(&:id))

    render inertia: "Clients/Index", props: {
      clients: ClientSerializer::List.new(clients, params: { unbilled_stats: unbilled_stats }).serializable_hash
    }
  end

  def show
    render inertia: "Clients/Show", props: {
      client: ClientSerializer.new(@client).serializable_hash,
      projects: ProjectSerializer::ForClientShow.new(@client.projects).serializable_hash,
      recent_work_entries: WorkEntrySerializer::Recent.new(recent_entries).serializable_hash,
      stats: ClientStatsService.new(@client).stats
    }
  end

  def new
    render inertia: "Clients/New", props: {
      client: ClientSerializer::Empty.serializable_hash
    }
  end

  def edit
    render inertia: "Clients/Edit", props: {
      client: ClientSerializer.new(@client).serializable_hash
    }
  end

  def create
    @client = Client.new(client_params)

    if @client.save
      redirect_to client_path(@client), notice: "Client created successfully."
    else
      redirect_to new_client_path, alert: @client.errors.full_messages.to_sentence
    end
  end

  def update
    if @client.update(client_params)
      redirect_to client_path(@client), notice: "Client updated successfully."
    else
      redirect_to edit_client_path(@client), alert: @client.errors.full_messages.to_sentence
    end
  end

  def destroy
    result = DeletionValidator.can_delete_client?(@client)

    if result[:valid]
      @client.destroy
      redirect_to clients_path, notice: "Client deleted successfully."
    else
      redirect_to client_path(@client), alert: result[:error]
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

  def recent_entries
    WorkEntry.joins(:project)
             .where(projects: { client_id: @client.id })
             .order(date: :desc)
             .limit(10)
             .includes(project: :client)
  end
end
