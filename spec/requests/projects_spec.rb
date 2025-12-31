require 'rails_helper'

RSpec.describe ProjectsController, type: :request do
  describe "GET /projects" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get projects_path
        expect(response).to have_http_status(:success)
      end

      it "renders the Projects/Index Inertia component" do
        get projects_path
        expect(response.body).to include('Projects/Index')
      end

      it "returns an empty list when no projects exist" do
        get projects_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        expect(json_response['props']['projects']).to eq([])
      end

      it "returns all projects grouped by client" do
        client = create(:client, name: "Acme Corp", currency: "EUR")
        project = create(:project, client: client, name: "Website Redesign", hourly_rate: 100, active: true)
        create(:work_entry, project: project, hours: 5, status: :unbilled)

        get projects_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        projects_data = json_response['props']['projects']

        expect(projects_data.length).to eq(1)
        expect(projects_data.first['client']['name']).to eq("Acme Corp")
        expect(projects_data.first['projects'].length).to eq(1)
        expect(projects_data.first['projects'].first['name']).to eq("Website Redesign")
        expect(projects_data.first['projects'].first['unbilled_hours']).to eq("5.0")
      end

      it "returns multiple projects from different clients" do
        client1 = create(:client, name: "Client A")
        client2 = create(:client, name: "Client B")
        create(:project, client: client1, name: "Project A1")
        create(:project, client: client2, name: "Project B1")

        get projects_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        projects_data = json_response['props']['projects']

        expect(projects_data.length).to eq(2)
      end

      it "filters projects by client_id when provided" do
        client1 = create(:client, name: "Client A")
        client2 = create(:client, name: "Client B")
        project1 = create(:project, client: client1, name: "Project A1")
        create(:project, client: client2, name: "Project B1")

        get projects_path(client_id: client1.id), headers: inertia_headers

        json_response = JSON.parse(response.body)
        projects_data = json_response['props']['projects']

        expect(projects_data.length).to eq(1)
        expect(projects_data.first['client']['name']).to eq("Client A")
        expect(projects_data.first['projects'].first['name']).to eq("Project A1")
      end

      it "includes clients for filter dropdown" do
        create(:client, name: "Client A")
        create(:client, name: "Client B")

        get projects_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        clients = json_response['props']['clients']

        expect(clients.length).to eq(2)
        expect(clients.map { |c| c['name'] }).to include("Client A", "Client B")
      end

      it "includes selected_client_id in props when filtering" do
        client = create(:client)

        get projects_path(client_id: client.id), headers: inertia_headers

        json_response = JSON.parse(response.body)
        expect(json_response['props']['selected_client_id']).to eq(client.id)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get projects_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /projects/:id" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        project = create(:project)
        get project_path(project)
        expect(response).to have_http_status(:success)
      end

      it "renders the Projects/Show Inertia component" do
        project = create(:project)
        get project_path(project)
        expect(response.body).to include('Projects/Show')
      end

      it "returns project data with all fields" do
        client = create(:client, name: "Acme Corp", currency: "EUR", hourly_rate: 100)
        project = create(:project,
          client: client,
          name: "Website Redesign",
          hourly_rate: 120,
          active: true
        )

        get project_path(project), headers: inertia_headers

        json_response = JSON.parse(response.body)
        project_data = json_response['props']['project']

        expect(project_data['name']).to eq("Website Redesign")
        expect(project_data['client_id']).to eq(client.id)
        expect(project_data['client_name']).to eq("Acme Corp")
        expect(project_data['client_currency']).to eq("EUR")
        expect(project_data['hourly_rate']).to eq("120.0")
        expect(project_data['effective_hourly_rate']).to eq("120.0")
        expect(project_data['active']).to eq(true)
      end

      it "returns project with effective_hourly_rate from client when project rate is nil" do
        client = create(:client, hourly_rate: 100)
        project = create(:project, client: client, hourly_rate: nil)

        get project_path(project), headers: inertia_headers

        json_response = JSON.parse(response.body)
        project_data = json_response['props']['project']

        expect(project_data['hourly_rate']).to be_nil
        expect(project_data['effective_hourly_rate']).to eq("100.0")
      end

      it "returns associated time entries" do
        project = create(:project)
        entry = create(:work_entry, project: project, date: Date.current, hours: 8, description: "Development work")

        get project_path(project), headers: inertia_headers

        json_response = JSON.parse(response.body)
        entries = json_response['props']['work_entries']

        expect(entries.length).to eq(1)
        expect(entries.first['hours']).to eq("8.0")
        expect(entries.first['description']).to eq("Development work")
        expect(entries.first['status']).to eq("unbilled")
      end

      it "returns project stats" do
        client = create(:client, hourly_rate: 100)
        project = create(:project, client: client, hourly_rate: 100)
        create(:work_entry, project: project, hours: 10, status: :unbilled)
        create(:work_entry, project: project, hours: 5, status: :invoiced)

        get project_path(project), headers: inertia_headers

        json_response = JSON.parse(response.body)
        stats = json_response['props']['stats']

        expect(stats['total_hours']).to eq("15.0")
        expect(stats['unbilled_hours']).to eq("10.0")
        expect(stats['unbilled_amount'].to_f).to eq(1000.0)
      end

      it "returns 404 for non-existent project" do
        get project_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        project = create(:project)
        get project_path(project)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /projects/new" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get new_project_path
        expect(response).to have_http_status(:success)
      end

      it "renders the Projects/New Inertia component" do
        get new_project_path
        expect(response.body).to include('Projects/New')
      end

      it "returns empty project data" do
        get new_project_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        project_data = json_response['props']['project']

        expect(project_data['id']).to be_nil
        expect(project_data['name']).to eq("")
        expect(project_data['client_id']).to be_nil
        expect(project_data['hourly_rate']).to be_nil
        expect(project_data['active']).to eq(true)
      end

      it "includes clients for selection" do
        create(:client, name: "Client A", hourly_rate: 100, currency: "EUR")
        create(:client, name: "Client B", hourly_rate: 120, currency: "USD")

        get new_project_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        clients = json_response['props']['clients']

        expect(clients.length).to eq(2)
        expect(clients.first['name']).to eq("Client A")
        expect(clients.first['hourly_rate']).to eq("100.0")
        expect(clients.first['currency']).to eq("EUR")
      end

      it "includes preselected_client_id when provided" do
        client = create(:client)

        get new_project_path(client_id: client.id), headers: inertia_headers

        json_response = JSON.parse(response.body)
        expect(json_response['props']['preselected_client_id']).to eq(client.id)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_project_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /projects/:id/edit" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        project = create(:project)
        get edit_project_path(project)
        expect(response).to have_http_status(:success)
      end

      it "renders the Projects/Edit Inertia component" do
        project = create(:project)
        get edit_project_path(project)
        expect(response.body).to include('Projects/Edit')
      end

      it "returns existing project data" do
        client = create(:client, name: "Acme Corp")
        project = create(:project, client: client, name: "Existing Project", hourly_rate: 150)

        get edit_project_path(project), headers: inertia_headers

        json_response = JSON.parse(response.body)
        project_data = json_response['props']['project']

        expect(project_data['id']).to eq(project.id)
        expect(project_data['name']).to eq("Existing Project")
        expect(project_data['client_id']).to eq(client.id)
        expect(project_data['hourly_rate']).to eq("150.0")
      end

      it "includes clients for selection" do
        client1 = create(:client, name: "Client A")
        client2 = create(:client, name: "Client B")
        project = create(:project, client: client1)

        get edit_project_path(project), headers: inertia_headers

        json_response = JSON.parse(response.body)
        clients = json_response['props']['clients']

        expect(clients.length).to eq(2)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        project = create(:project)
        get edit_project_path(project)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /projects" do
    context "when authenticated" do
      before { sign_in }

      context "with valid params" do
        it "creates a new project" do
          client = create(:client)

          expect {
            post projects_path, params: {
              project: { name: "New Project", client_id: client.id }
            }
          }.to change(Project, :count).by(1)
        end

        it "redirects to the project show page with success notice" do
          client = create(:client)

          post projects_path, params: {
            project: { name: "New Project", client_id: client.id }
          }

          project = Project.last
          expect(response).to redirect_to(project_path(project))
          follow_redirect!
          expect(flash[:notice]).to eq("Project created successfully.")
        end

        it "creates project with all fields" do
          client = create(:client)

          post projects_path, params: {
            project: {
              name: "Full Project",
              client_id: client.id,
              hourly_rate: 150,
              active: true
            }
          }

          project = Project.last
          expect(project.name).to eq("Full Project")
          expect(project.client_id).to eq(client.id)
          expect(project.hourly_rate).to eq(150)
          expect(project.active).to eq(true)
        end

        it "creates inactive project when active is false" do
          client = create(:client)

          post projects_path, params: {
            project: {
              name: "Inactive Project",
              client_id: client.id,
              active: false
            }
          }

          project = Project.last
          expect(project.active).to eq(false)
        end
      end

      context "with invalid params" do
        it "does not create a project without a name" do
          client = create(:client)

          expect {
            post projects_path, params: {
              project: { name: "", client_id: client.id }
            }
          }.not_to change(Project, :count)
        end

        it "redirects to new with an error message" do
          client = create(:client)

          post projects_path, params: {
            project: { name: "", client_id: client.id }
          }

          expect(response).to redirect_to(new_project_path(client_id: client.id))
          follow_redirect!
          expect(flash[:alert]).to include("Name")
        end

        it "does not create a project without a client" do
          expect {
            post projects_path, params: {
              project: { name: "Test Project" }
            }
          }.not_to change(Project, :count)
        end

        it "returns error for negative hourly rate" do
          client = create(:client)

          post projects_path, params: {
            project: { name: "Test", client_id: client.id, hourly_rate: -10 }
          }

          expect(response).to redirect_to(new_project_path(client_id: client.id))
          follow_redirect!
          expect(flash[:alert]).to include("Hourly rate")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        client = create(:client)
        post projects_path, params: {
          project: { name: "Test", client_id: client.id }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /projects/:id" do
    context "when authenticated" do
      before { sign_in }

      context "with valid params" do
        it "updates the project" do
          project = create(:project, name: "Old Name")

          patch project_path(project), params: {
            project: { name: "New Name" }
          }

          expect(project.reload.name).to eq("New Name")
        end

        it "redirects to project show with success notice" do
          project = create(:project)

          patch project_path(project), params: {
            project: { name: "Updated Project" }
          }

          expect(response).to redirect_to(project_path(project))
          follow_redirect!
          expect(flash[:notice]).to eq("Project updated successfully.")
        end

        it "updates all project fields" do
          client1 = create(:client)
          client2 = create(:client)
          project = create(:project, client: client1, name: "Original", hourly_rate: 100, active: true)

          patch project_path(project), params: {
            project: {
              name: "Updated",
              client_id: client2.id,
              hourly_rate: 200,
              active: false
            }
          }

          project.reload
          expect(project.name).to eq("Updated")
          expect(project.client_id).to eq(client2.id)
          expect(project.hourly_rate).to eq(200)
          expect(project.active).to eq(false)
        end

        it "can set hourly_rate to nil" do
          project = create(:project, hourly_rate: 100)

          patch project_path(project), params: {
            project: { hourly_rate: "" }
          }

          expect(project.reload.hourly_rate).to be_nil
        end
      end

      context "with invalid params" do
        it "does not update with blank name" do
          project = create(:project, name: "Original")

          patch project_path(project), params: {
            project: { name: "" }
          }

          expect(project.reload.name).to eq("Original")
        end

        it "redirects to edit with an error message" do
          project = create(:project)

          patch project_path(project), params: {
            project: { name: "" }
          }

          expect(response).to redirect_to(edit_project_path(project))
          follow_redirect!
          expect(flash[:alert]).to include("Name")
        end

        it "returns error for negative hourly rate" do
          project = create(:project)

          patch project_path(project), params: {
            project: { hourly_rate: -10 }
          }

          expect(response).to redirect_to(edit_project_path(project))
          follow_redirect!
          expect(flash[:alert]).to include("Hourly rate")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        project = create(:project)
        patch project_path(project), params: {
          project: { name: "Test" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /projects/:id" do
    context "when authenticated" do
      before { sign_in }

      context "when project has no time entries" do
        it "deletes the project" do
          project = create(:project)

          expect {
            delete project_path(project)
          }.to change(Project, :count).by(-1)
        end

        it "redirects to projects index with success notice" do
          project = create(:project)

          delete project_path(project)

          expect(response).to redirect_to(projects_path)
          follow_redirect!
          expect(flash[:notice]).to eq("Project deleted successfully.")
        end
      end

      context "when project has unbilled time entries" do
        it "deletes the project and its time entries" do
          project = create(:project)
          create(:work_entry, project: project, status: :unbilled)

          expect {
            delete project_path(project)
          }.to change(Project, :count).by(-1)
            .and change(WorkEntry, :count).by(-1)
        end
      end

      context "when project has invoiced time entries" do
        it "does not delete the project" do
          project = create(:project)
          create(:work_entry, project: project, status: :invoiced)

          expect {
            delete project_path(project)
          }.not_to change(Project, :count)
        end

        it "redirects to project show with error message" do
          project = create(:project)
          create(:work_entry, project: project, status: :invoiced)

          delete project_path(project)

          expect(response).to redirect_to(project_path(project))
          follow_redirect!
          expect(flash[:alert]).to eq("Cannot delete project with invoiced work entries.")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        project = create(:project)
        delete project_path(project)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /projects/:id/toggle_active" do
    context "when authenticated" do
      before { sign_in }

      it "toggles project from active to inactive" do
        project = create(:project, active: true)

        patch toggle_active_project_path(project)

        expect(project.reload.active).to eq(false)
      end

      it "toggles project from inactive to active" do
        project = create(:project, active: false)

        patch toggle_active_project_path(project)

        expect(project.reload.active).to eq(true)
      end

      it "redirects to project show with deactivated message" do
        project = create(:project, active: true)

        patch toggle_active_project_path(project)

        expect(response).to redirect_to(project_path(project))
        follow_redirect!
        expect(flash[:notice]).to eq("Project deactivated successfully.")
      end

      it "redirects to project show with activated message" do
        project = create(:project, active: false)

        patch toggle_active_project_path(project)

        expect(response).to redirect_to(project_path(project))
        follow_redirect!
        expect(flash[:notice]).to eq("Project activated successfully.")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        project = create(:project)
        patch toggle_active_project_path(project)
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
