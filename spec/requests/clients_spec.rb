require 'rails_helper'

RSpec.describe ClientsController, type: :request do
  describe "GET /clients" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get clients_path
        expect(response).to have_http_status(:success)
      end

      it "renders the Clients/Index Inertia component" do
        get clients_path
        expect(response.body).to include('Clients/Index')
      end

      it "returns an empty list when no clients exist" do
        get clients_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        expect(json_response['props']['clients']).to eq([])
      end

      it "returns all clients with computed fields" do
        client = create(:client, name: "Acme Corp", currency: "EUR", hourly_rate: 100)
        project = create(:project, client: client, hourly_rate: 100)
        create(:work_entry, project: project, hours: 5, status: :unbilled)

        get clients_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        clients = json_response['props']['clients']

        expect(clients.length).to eq(1)
        expect(clients.first['name']).to eq("Acme Corp")
        expect(clients.first['currency']).to eq("EUR")
        expect(clients.first['hourly_rate']).to eq("100.0")
        expect(clients.first['unbilled_hours']).to eq("5.0")
        expect(clients.first['unbilled_amount'].to_f).to eq(500.0)
        expect(clients.first['projects_count']).to eq(1)
      end

      it "returns multiple clients" do
        create(:client, name: "Client A")
        create(:client, name: "Client B")

        get clients_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        expect(json_response['props']['clients'].length).to eq(2)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get clients_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /clients/:id" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        client = create(:client)
        get client_path(client)
        expect(response).to have_http_status(:success)
      end

      it "renders the Clients/Show Inertia component" do
        client = create(:client)
        get client_path(client)
        expect(response.body).to include('Clients/Show')
      end

      it "returns client data with all fields" do
        client = create(:client,
          name: "Acme Corp",
          email: "contact@acme.com",
          address: "123 Main St",
          contact_person: "John Doe",
          vat_id: "VAT123",
          company_registration: "REG456",
          bank_details: "Bank Info",
          payment_terms: "Net 30",
          hourly_rate: 120,
          currency: "EUR"
        )

        get client_path(client), headers: inertia_headers

        json_response = JSON.parse(response.body)
        client_data = json_response['props']['client']

        expect(client_data['name']).to eq("Acme Corp")
        expect(client_data['email']).to eq("contact@acme.com")
        expect(client_data['address']).to eq("123 Main St")
        expect(client_data['contact_person']).to eq("John Doe")
        expect(client_data['vat_id']).to eq("VAT123")
        expect(client_data['company_registration']).to eq("REG456")
        expect(client_data['bank_details']).to eq("Bank Info")
        expect(client_data['payment_terms']).to eq("Net 30")
        expect(client_data['hourly_rate']).to eq("120.0")
        expect(client_data['currency']).to eq("EUR")
        expect(client_data['share_token']).to be_present
      end

      it "returns associated projects" do
        client = create(:client)
        project = create(:project, client: client, name: "Project Alpha", hourly_rate: 100, active: true)

        get client_path(client), headers: inertia_headers

        json_response = JSON.parse(response.body)
        projects = json_response['props']['projects']

        expect(projects.length).to eq(1)
        expect(projects.first['name']).to eq("Project Alpha")
        expect(projects.first['hourly_rate']).to eq("100.0")
        expect(projects.first['active']).to eq(true)
      end

      it "returns recent time entries" do
        client = create(:client)
        project = create(:project, client: client, name: "Project Alpha")
        entry = create(:work_entry, project: project, date: Date.current, hours: 8, description: "Work")

        get client_path(client), headers: inertia_headers

        json_response = JSON.parse(response.body)
        entries = json_response['props']['recent_work_entries']

        expect(entries.length).to eq(1)
        expect(entries.first['hours']).to eq("8.0")
        expect(entries.first['description']).to eq("Work")
        expect(entries.first['project_name']).to eq("Project Alpha")
      end

      it "returns client stats" do
        client = create(:client, hourly_rate: 100)
        project = create(:project, client: client, hourly_rate: 100)
        create(:work_entry, project: project, hours: 10, status: :unbilled)
        create(:work_entry, project: project, hours: 5, status: :invoiced)
        create(:invoice, client: client, status: :final, total_amount: 500)

        get client_path(client), headers: inertia_headers

        json_response = JSON.parse(response.body)
        stats = json_response['props']['stats']

        expect(stats['total_hours']).to eq("15.0")
        expect(stats['unbilled_hours']).to eq("10.0")
        expect(stats['unbilled_amount'].to_f).to eq(1000.0)
        expect(stats['total_invoiced']).to eq("500.0")
      end

      it "returns 404 for non-existent client" do
        get client_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        client = create(:client)
        get client_path(client)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /clients/new" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get new_client_path
        expect(response).to have_http_status(:success)
      end

      it "renders the Clients/New Inertia component" do
        get new_client_path
        expect(response.body).to include('Clients/New')
      end

      it "returns empty client data" do
        get new_client_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        client_data = json_response['props']['client']

        expect(client_data['id']).to be_nil
        expect(client_data['name']).to eq("")
        expect(client_data['email']).to eq("")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_client_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /clients/:id/edit" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        client = create(:client)
        get edit_client_path(client)
        expect(response).to have_http_status(:success)
      end

      it "renders the Clients/Edit Inertia component" do
        client = create(:client)
        get edit_client_path(client)
        expect(response.body).to include('Clients/Edit')
      end

      it "returns existing client data" do
        client = create(:client, name: "Existing Client", email: "test@example.com")

        get edit_client_path(client), headers: inertia_headers

        json_response = JSON.parse(response.body)
        client_data = json_response['props']['client']

        expect(client_data['id']).to eq(client.id)
        expect(client_data['name']).to eq("Existing Client")
        expect(client_data['email']).to eq("test@example.com")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        client = create(:client)
        get edit_client_path(client)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /clients" do
    context "when authenticated" do
      before { sign_in }

      context "with valid params" do
        it "creates a new client" do
          expect {
            post clients_path, params: {
              client: { name: "New Client", email: "new@example.com" }
            }
          }.to change(Client, :count).by(1)
        end

        it "redirects to the client show page with success notice" do
          post clients_path, params: {
            client: { name: "New Client" }
          }

          client = Client.last
          expect(response).to redirect_to(client_path(client))
          follow_redirect!
          expect(flash[:notice]).to eq("Client created successfully.")
        end

        it "creates client with all fields" do
          post clients_path, params: {
            client: {
              name: "Full Client",
              address: "123 Main St",
              email: "full@example.com",
              contact_person: "Jane Doe",
              vat_id: "VAT456",
              company_registration: "REG789",
              bank_details: "Bank Info",
              payment_terms: "Net 15",
              hourly_rate: 150,
              currency: "USD"
            }
          }

          client = Client.last
          expect(client.name).to eq("Full Client")
          expect(client.address).to eq("123 Main St")
          expect(client.email).to eq("full@example.com")
          expect(client.contact_person).to eq("Jane Doe")
          expect(client.vat_id).to eq("VAT456")
          expect(client.company_registration).to eq("REG789")
          expect(client.bank_details).to eq("Bank Info")
          expect(client.payment_terms).to eq("Net 15")
          expect(client.hourly_rate).to eq(150)
          expect(client.currency).to eq("USD")
          expect(client.share_token).to be_present
        end
      end

      context "with invalid params" do
        it "does not create a client without a name" do
          expect {
            post clients_path, params: {
              client: { name: "", email: "test@example.com" }
            }
          }.not_to change(Client, :count)
        end

        it "redirects to new with an error message" do
          post clients_path, params: {
            client: { name: "" }
          }

          expect(response).to redirect_to(new_client_path)
          follow_redirect!
          expect(flash[:alert]).to include("Name")
        end

        it "returns error for invalid email format" do
          post clients_path, params: {
            client: { name: "Test", email: "invalid-email" }
          }

          expect(response).to redirect_to(new_client_path)
          follow_redirect!
          expect(flash[:alert]).to include("Email")
        end

        it "returns error for invalid currency format" do
          post clients_path, params: {
            client: { name: "Test", currency: "euro" }
          }

          expect(response).to redirect_to(new_client_path)
          follow_redirect!
          expect(flash[:alert]).to include("Currency")
        end

        it "returns error for negative hourly rate" do
          post clients_path, params: {
            client: { name: "Test", hourly_rate: -10 }
          }

          expect(response).to redirect_to(new_client_path)
          follow_redirect!
          expect(flash[:alert]).to include("Hourly rate")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post clients_path, params: {
          client: { name: "Test" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /clients/:id" do
    context "when authenticated" do
      before { sign_in }

      context "with valid params" do
        it "updates the client" do
          client = create(:client, name: "Old Name")

          patch client_path(client), params: {
            client: { name: "New Name" }
          }

          expect(client.reload.name).to eq("New Name")
        end

        it "redirects to client show with success notice" do
          client = create(:client)

          patch client_path(client), params: {
            client: { name: "Updated Client" }
          }

          expect(response).to redirect_to(client_path(client))
          follow_redirect!
          expect(flash[:notice]).to eq("Client updated successfully.")
        end

        it "updates all client fields" do
          client = create(:client, :minimal)

          patch client_path(client), params: {
            client: {
              name: "Updated Corp",
              address: "456 New St",
              email: "updated@example.com",
              contact_person: "New Person",
              vat_id: "NEWVAT",
              company_registration: "NEWREG",
              bank_details: "New Bank",
              payment_terms: "Net 45",
              hourly_rate: 200,
              currency: "GBP"
            }
          }

          client.reload
          expect(client.name).to eq("Updated Corp")
          expect(client.address).to eq("456 New St")
          expect(client.email).to eq("updated@example.com")
          expect(client.contact_person).to eq("New Person")
          expect(client.vat_id).to eq("NEWVAT")
          expect(client.company_registration).to eq("NEWREG")
          expect(client.bank_details).to eq("New Bank")
          expect(client.payment_terms).to eq("Net 45")
          expect(client.hourly_rate).to eq(200)
          expect(client.currency).to eq("GBP")
        end
      end

      context "with invalid params" do
        it "does not update with blank name" do
          client = create(:client, name: "Original")

          patch client_path(client), params: {
            client: { name: "" }
          }

          expect(client.reload.name).to eq("Original")
        end

        it "redirects to edit with an error message" do
          client = create(:client)

          patch client_path(client), params: {
            client: { name: "" }
          }

          expect(response).to redirect_to(edit_client_path(client))
          follow_redirect!
          expect(flash[:alert]).to include("Name")
        end

        it "returns error for invalid email format" do
          client = create(:client)

          patch client_path(client), params: {
            client: { email: "bad-email" }
          }

          expect(response).to redirect_to(edit_client_path(client))
          follow_redirect!
          expect(flash[:alert]).to include("Email")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        client = create(:client)
        patch client_path(client), params: {
          client: { name: "Test" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /clients/:id" do
    context "when authenticated" do
      before { sign_in }

      context "when client has no associations" do
        it "deletes the client" do
          client = create(:client)

          expect {
            delete client_path(client)
          }.to change(Client, :count).by(-1)
        end

        it "redirects to clients index with success notice" do
          client = create(:client)

          delete client_path(client)

          expect(response).to redirect_to(clients_path)
          follow_redirect!
          expect(flash[:notice]).to eq("Client deleted successfully.")
        end
      end

      context "when client has associated projects" do
        it "does not delete the client" do
          client = create(:client)
          create(:project, client: client)

          expect {
            delete client_path(client)
          }.not_to change(Client, :count)
        end

        it "redirects to client show with error message" do
          client = create(:client)
          create(:project, client: client)

          delete client_path(client)

          expect(response).to redirect_to(client_path(client))
          follow_redirect!
          expect(flash[:alert]).to eq("Cannot delete client with associated projects or invoices.")
        end
      end

      context "when client has associated invoices" do
        it "does not delete the client" do
          client = create(:client)
          create(:invoice, client: client)

          expect {
            delete client_path(client)
          }.not_to change(Client, :count)
        end

        it "redirects to client show with error message" do
          client = create(:client)
          create(:invoice, client: client)

          delete client_path(client)

          expect(response).to redirect_to(client_path(client))
          follow_redirect!
          expect(flash[:alert]).to eq("Cannot delete client with associated projects or invoices.")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        client = create(:client)
        delete client_path(client)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  private

  def inertia_headers
    {
      'X-Inertia' => 'true',
      'X-Inertia-Version' => ViteRuby.digest
    }
  end
end
