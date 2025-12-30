require 'rails_helper'

RSpec.describe TimeEntriesController, type: :request do
  describe "GET /time_entries" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get time_entries_path
        expect(response).to have_http_status(:success)
      end

      it "renders the TimeEntries/Index Inertia component" do
        get time_entries_path
        expect(response.body).to include('TimeEntries/Index')
      end

      it "returns an empty list when no time entries exist" do
        get time_entries_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        expect(json_response['props']['date_groups']).to eq([])
      end

      it "returns time entries grouped by date" do
        client = create(:client, name: "Acme Corp", currency: "EUR", hourly_rate: 100)
        project = create(:project, client: client, name: "Website", hourly_rate: 100)
        entry = create(:time_entry, project: project, date: Date.current, hours: 8, description: "Development work")

        get time_entries_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        date_groups = json_response['props']['date_groups']

        expect(date_groups.length).to eq(1)
        expect(date_groups.first['formatted_date']).to eq("Today")
        expect(date_groups.first['total_hours']).to eq("8.0")
        expect(date_groups.first['entries'].length).to eq(1)
        expect(date_groups.first['entries'].first['description']).to eq("Development work")
      end

      it "returns entries sorted by date descending" do
        client = create(:client, hourly_rate: 100)
        project = create(:project, client: client)
        create(:time_entry, project: project, date: Date.yesterday, description: "Yesterday's work")
        create(:time_entry, project: project, date: Date.current, description: "Today's work")
        create(:time_entry, project: project, date: 2.days.ago.to_date, description: "Older work")

        get time_entries_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        date_groups = json_response['props']['date_groups']

        expect(date_groups.length).to eq(3)
        expect(date_groups.first['formatted_date']).to eq("Today")
        expect(date_groups.second['formatted_date']).to eq("Yesterday")
      end

      it "includes project and client info in each entry" do
        client = create(:client, name: "Acme Corp", currency: "EUR", hourly_rate: 100)
        project = create(:project, client: client, name: "Website", hourly_rate: 120)
        entry = create(:time_entry, project: project)

        get time_entries_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        entry_data = json_response['props']['date_groups'].first['entries'].first

        expect(entry_data['project_name']).to eq("Website")
        expect(entry_data['client_name']).to eq("Acme Corp")
        expect(entry_data['client_currency']).to eq("EUR")
        expect(entry_data['calculated_amount'].to_f).to eq(960.0) # 8 hours * 120
      end

      context "filtering" do
        let!(:client1) { create(:client, name: "Client A", hourly_rate: 100) }
        let!(:client2) { create(:client, name: "Client B", hourly_rate: 100) }
        let!(:project1) { create(:project, client: client1, name: "Project A") }
        let!(:project2) { create(:project, client: client2, name: "Project B") }
        let!(:entry1) { create(:time_entry, project: project1, date: Date.current, description: "Work A") }
        let!(:entry2) { create(:time_entry, project: project2, date: Date.current, description: "Work B") }
        let!(:old_entry) { create(:time_entry, project: project1, date: 1.month.ago.to_date, description: "Old work") }

        it "filters by client_id" do
          get time_entries_path(client_id: client1.id), headers: inertia_headers

          json_response = JSON.parse(response.body)
          entries = json_response['props']['date_groups'].flat_map { |g| g['entries'] }

          expect(entries.length).to eq(2)
          expect(entries.map { |e| e['description'] }).to include("Work A", "Old work")
          expect(entries.map { |e| e['description'] }).not_to include("Work B")
        end

        it "filters by project_id" do
          get time_entries_path(project_id: project1.id), headers: inertia_headers

          json_response = JSON.parse(response.body)
          entries = json_response['props']['date_groups'].flat_map { |g| g['entries'] }

          expect(entries.length).to eq(2)
          expect(entries.map { |e| e['description'] }).to include("Work A", "Old work")
        end

        it "filters by date range" do
          start_date = 1.week.ago.to_date
          end_date = Date.current

          get time_entries_path(start_date: start_date, end_date: end_date), headers: inertia_headers

          json_response = JSON.parse(response.body)
          entries = json_response['props']['date_groups'].flat_map { |g| g['entries'] }

          expect(entries.length).to eq(2)
          expect(entries.map { |e| e['description'] }).not_to include("Old work")
        end

        it "filters by start_date only" do
          start_date = 1.week.ago.to_date

          get time_entries_path(start_date: start_date), headers: inertia_headers

          json_response = JSON.parse(response.body)
          entries = json_response['props']['date_groups'].flat_map { |g| g['entries'] }

          expect(entries.length).to eq(2)
        end

        it "filters by end_date only" do
          end_date = 1.week.ago.to_date

          get time_entries_path(end_date: end_date), headers: inertia_headers

          json_response = JSON.parse(response.body)
          entries = json_response['props']['date_groups'].flat_map { |g| g['entries'] }

          expect(entries.length).to eq(1)
          expect(entries.first['description']).to eq("Old work")
        end

        it "combines multiple filters" do
          get time_entries_path(client_id: client1.id, start_date: 1.week.ago.to_date), headers: inertia_headers

          json_response = JSON.parse(response.body)
          entries = json_response['props']['date_groups'].flat_map { |g| g['entries'] }

          expect(entries.length).to eq(1)
          expect(entries.first['description']).to eq("Work A")
        end

        it "returns current filters in props" do
          get time_entries_path(client_id: client1.id, start_date: "2024-01-01"), headers: inertia_headers

          json_response = JSON.parse(response.body)
          filters = json_response['props']['filters']

          expect(filters['client_id']).to eq(client1.id)
          expect(filters['start_date']).to eq("2024-01-01")
        end
      end

      it "includes projects grouped by client for dropdown" do
        client = create(:client, name: "Acme Corp", currency: "EUR")
        project = create(:project, client: client, name: "Website", active: true)

        get time_entries_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        projects = json_response['props']['projects']

        expect(projects.length).to eq(1)
        expect(projects.first['client']['name']).to eq("Acme Corp")
        expect(projects.first['projects'].first['name']).to eq("Website")
      end

      it "excludes inactive projects from dropdown" do
        client = create(:client, name: "Acme Corp")
        create(:project, client: client, name: "Active Project", active: true)
        create(:project, client: client, name: "Inactive Project", active: false)

        get time_entries_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        project_names = json_response['props']['projects'].flat_map { |g| g['projects'].map { |p| p['name'] } }

        expect(project_names).to include("Active Project")
        expect(project_names).not_to include("Inactive Project")
      end

      it "includes clients for filter dropdown" do
        create(:client, name: "Client A")
        create(:client, name: "Client B")

        get time_entries_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        clients = json_response['props']['clients']

        expect(clients.length).to eq(2)
        expect(clients.map { |c| c['name'] }).to include("Client A", "Client B")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get time_entries_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /time_entries/:id" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        entry = create(:time_entry)
        get time_entry_path(entry)
        expect(response).to have_http_status(:success)
      end

      it "renders the TimeEntries/Show Inertia component" do
        entry = create(:time_entry)
        get time_entry_path(entry)
        expect(response.body).to include('TimeEntries/Show')
      end

      it "returns time entry data with all fields" do
        client = create(:client, name: "Acme Corp", currency: "EUR", hourly_rate: 100)
        project = create(:project, client: client, name: "Website", hourly_rate: 120)
        entry = create(:time_entry, project: project, date: Date.current, hours: 4, description: "Dev work")

        get time_entry_path(entry), headers: inertia_headers

        json_response = JSON.parse(response.body)
        entry_data = json_response['props']['time_entry']

        expect(entry_data['id']).to eq(entry.id)
        expect(entry_data['date']).to eq(Date.current.to_s)
        expect(entry_data['hours']).to eq("4.0")
        expect(entry_data['description']).to eq("Dev work")
        expect(entry_data['status']).to eq("unbilled")
        expect(entry_data['project_name']).to eq("Website")
        expect(entry_data['client_name']).to eq("Acme Corp")
        expect(entry_data['client_currency']).to eq("EUR")
        expect(entry_data['effective_hourly_rate']).to eq("120.0")
        expect(entry_data['calculated_amount'].to_f).to eq(480.0)
      end

      it "returns 404 for non-existent time entry" do
        get time_entry_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        entry = create(:time_entry)
        get time_entry_path(entry)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /time_entries/new" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get new_time_entry_path
        expect(response).to have_http_status(:success)
      end

      it "renders the TimeEntries/New Inertia component" do
        get new_time_entry_path
        expect(response.body).to include('TimeEntries/New')
      end

      it "returns empty time entry data with today's date" do
        get new_time_entry_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        entry_data = json_response['props']['time_entry']

        expect(entry_data['id']).to be_nil
        expect(entry_data['date']).to eq(Date.current.to_s)
        expect(entry_data['hours']).to be_nil
        expect(entry_data['description']).to eq("")
        expect(entry_data['project_id']).to be_nil
      end

      it "includes projects grouped by client" do
        client = create(:client, name: "Acme Corp", currency: "EUR")
        project = create(:project, client: client, name: "Website", active: true)

        get new_time_entry_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        projects = json_response['props']['projects']

        expect(projects.length).to eq(1)
        expect(projects.first['client']['name']).to eq("Acme Corp")
      end

      it "includes preselected_project_id when provided" do
        project = create(:project)

        get new_time_entry_path(project_id: project.id), headers: inertia_headers

        json_response = JSON.parse(response.body)
        expect(json_response['props']['preselected_project_id']).to eq(project.id)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_time_entry_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /time_entries/:id/edit" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        entry = create(:time_entry)
        get edit_time_entry_path(entry)
        expect(response).to have_http_status(:success)
      end

      it "renders the TimeEntries/Edit Inertia component" do
        entry = create(:time_entry)
        get edit_time_entry_path(entry)
        expect(response.body).to include('TimeEntries/Edit')
      end

      it "returns existing time entry data" do
        project = create(:project, name: "Website")
        entry = create(:time_entry, project: project, hours: 6, description: "Existing work")

        get edit_time_entry_path(entry), headers: inertia_headers

        json_response = JSON.parse(response.body)
        entry_data = json_response['props']['time_entry']

        expect(entry_data['id']).to eq(entry.id)
        expect(entry_data['hours']).to eq("6.0")
        expect(entry_data['description']).to eq("Existing work")
        expect(entry_data['project_id']).to eq(project.id)
      end

      it "includes projects for selection" do
        client = create(:client, name: "Acme Corp")
        project = create(:project, client: client, name: "Website", active: true)
        entry = create(:time_entry, project: project)

        get edit_time_entry_path(entry), headers: inertia_headers

        json_response = JSON.parse(response.body)
        projects = json_response['props']['projects']

        expect(projects.length).to eq(1)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        entry = create(:time_entry)
        get edit_time_entry_path(entry)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /time_entries" do
    context "when authenticated" do
      before { sign_in }

      context "with valid params" do
        it "creates a new time entry" do
          project = create(:project)

          expect {
            post time_entries_path, params: {
              time_entry: { project_id: project.id, date: Date.current, hours: 8, description: "New work" }
            }
          }.to change(TimeEntry, :count).by(1)
        end

        it "redirects to time entries index with success notice" do
          project = create(:project)

          post time_entries_path, params: {
            time_entry: { project_id: project.id, date: Date.current, hours: 8, description: "New work" }
          }

          expect(response).to redirect_to(time_entries_path)
          follow_redirect!
          expect(flash[:notice]).to eq("Time entry created successfully.")
        end

        it "creates time entry with unbilled status by default" do
          project = create(:project)

          post time_entries_path, params: {
            time_entry: { project_id: project.id, date: Date.current, hours: 8 }
          }

          entry = TimeEntry.last
          expect(entry.status).to eq("unbilled")
        end

        it "creates time entry with all fields" do
          project = create(:project)
          date = Date.yesterday

          post time_entries_path, params: {
            time_entry: {
              project_id: project.id,
              date: date,
              hours: 4.5,
              description: "Detailed work description"
            }
          }

          entry = TimeEntry.last
          expect(entry.project_id).to eq(project.id)
          expect(entry.date).to eq(date)
          expect(entry.hours).to eq(4.5)
          expect(entry.description).to eq("Detailed work description")
        end
      end

      context "with invalid params" do
        it "does not create a time entry without hours" do
          project = create(:project)

          expect {
            post time_entries_path, params: {
              time_entry: { project_id: project.id, date: Date.current, hours: nil }
            }
          }.not_to change(TimeEntry, :count)
        end

        it "redirects to new with an error message" do
          project = create(:project)

          post time_entries_path, params: {
            time_entry: { project_id: project.id, date: Date.current, hours: nil }
          }

          expect(response).to redirect_to(new_time_entry_path(project_id: project.id))
          follow_redirect!
          expect(flash[:alert]).to include("Hours")
        end

        it "does not create a time entry without a project" do
          expect {
            post time_entries_path, params: {
              time_entry: { date: Date.current, hours: 8 }
            }
          }.not_to change(TimeEntry, :count)
        end

        it "does not create a time entry without a date" do
          project = create(:project)

          expect {
            post time_entries_path, params: {
              time_entry: { project_id: project.id, hours: 8, date: nil }
            }
          }.not_to change(TimeEntry, :count)
        end

        it "returns error for zero hours" do
          project = create(:project)

          post time_entries_path, params: {
            time_entry: { project_id: project.id, date: Date.current, hours: 0 }
          }

          expect(response).to redirect_to(new_time_entry_path(project_id: project.id))
          follow_redirect!
          expect(flash[:alert]).to include("Hours")
        end

        it "returns error for negative hours" do
          project = create(:project)

          post time_entries_path, params: {
            time_entry: { project_id: project.id, date: Date.current, hours: -5 }
          }

          expect(response).to redirect_to(new_time_entry_path(project_id: project.id))
          follow_redirect!
          expect(flash[:alert]).to include("Hours")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        project = create(:project)
        post time_entries_path, params: {
          time_entry: { project_id: project.id, date: Date.current, hours: 8 }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /time_entries/:id" do
    context "when authenticated" do
      before { sign_in }

      context "when entry is unbilled" do
        context "with valid params" do
          it "updates the time entry" do
            entry = create(:time_entry, status: :unbilled, hours: 4)

            patch time_entry_path(entry), params: {
              time_entry: { hours: 8 }
            }

            expect(entry.reload.hours).to eq(8)
          end

          it "redirects to time entries index with success notice" do
            entry = create(:time_entry, status: :unbilled)

            patch time_entry_path(entry), params: {
              time_entry: { description: "Updated work" }
            }

            expect(response).to redirect_to(time_entries_path)
            follow_redirect!
            expect(flash[:notice]).to eq("Time entry updated successfully.")
          end

          it "updates all time entry fields" do
            project1 = create(:project)
            project2 = create(:project)
            entry = create(:time_entry, project: project1, date: Date.yesterday, hours: 4, description: "Original", status: :unbilled)

            patch time_entry_path(entry), params: {
              time_entry: {
                project_id: project2.id,
                date: Date.current,
                hours: 6,
                description: "Updated"
              }
            }

            entry.reload
            expect(entry.project_id).to eq(project2.id)
            expect(entry.date).to eq(Date.current)
            expect(entry.hours).to eq(6)
            expect(entry.description).to eq("Updated")
          end
        end

        context "with invalid params" do
          it "does not update with zero hours" do
            entry = create(:time_entry, status: :unbilled, hours: 4)

            patch time_entry_path(entry), params: {
              time_entry: { hours: 0 }
            }

            expect(entry.reload.hours).to eq(4)
          end

          it "redirects to edit with an error message" do
            entry = create(:time_entry, status: :unbilled)

            patch time_entry_path(entry), params: {
              time_entry: { hours: 0 }
            }

            expect(response).to redirect_to(edit_time_entry_path(entry))
            follow_redirect!
            expect(flash[:alert]).to include("Hours")
          end
        end
      end

      context "when entry is invoiced" do
        it "does not update the time entry" do
          entry = create(:time_entry, status: :invoiced, hours: 4)

          patch time_entry_path(entry), params: {
            time_entry: { hours: 8 }
          }

          expect(entry.reload.hours).to eq(4)
        end

        it "redirects to time entries index with error message" do
          entry = create(:time_entry, status: :invoiced)

          patch time_entry_path(entry), params: {
            time_entry: { hours: 8 }
          }

          expect(response).to redirect_to(time_entries_path)
          follow_redirect!
          expect(flash[:alert]).to eq("Cannot update an invoiced time entry.")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        entry = create(:time_entry)
        patch time_entry_path(entry), params: {
          time_entry: { hours: 8 }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /time_entries/:id" do
    context "when authenticated" do
      before { sign_in }

      context "when entry is unbilled" do
        it "deletes the time entry" do
          entry = create(:time_entry, status: :unbilled)

          expect {
            delete time_entry_path(entry)
          }.to change(TimeEntry, :count).by(-1)
        end

        it "redirects to time entries index with success notice" do
          entry = create(:time_entry, status: :unbilled)

          delete time_entry_path(entry)

          expect(response).to redirect_to(time_entries_path)
          follow_redirect!
          expect(flash[:notice]).to eq("Time entry deleted successfully.")
        end
      end

      context "when entry is invoiced" do
        it "does not delete the time entry" do
          entry = create(:time_entry, status: :invoiced)

          expect {
            delete time_entry_path(entry)
          }.not_to change(TimeEntry, :count)
        end

        it "redirects to time entries index with error message" do
          entry = create(:time_entry, status: :invoiced)

          delete time_entry_path(entry)

          expect(response).to redirect_to(time_entries_path)
          follow_redirect!
          expect(flash[:alert]).to eq("Cannot delete an invoiced time entry.")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        entry = create(:time_entry)
        delete time_entry_path(entry)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /time_entries/bulk_destroy" do
    context "when authenticated" do
      before { sign_in }

      it "deletes multiple unbilled time entries" do
        entry1 = create(:time_entry, status: :unbilled)
        entry2 = create(:time_entry, status: :unbilled)

        expect {
          delete bulk_destroy_time_entries_path, params: { ids: [entry1.id, entry2.id] }
        }.to change(TimeEntry, :count).by(-2)
      end

      it "only deletes unbilled entries" do
        unbilled_entry = create(:time_entry, status: :unbilled)
        invoiced_entry = create(:time_entry, status: :invoiced)

        expect {
          delete bulk_destroy_time_entries_path, params: { ids: [unbilled_entry.id, invoiced_entry.id] }
        }.to change(TimeEntry, :count).by(-1)

        expect(TimeEntry.exists?(invoiced_entry.id)).to be true
        expect(TimeEntry.exists?(unbilled_entry.id)).to be false
      end

      it "redirects with correct count message for single entry" do
        entry = create(:time_entry, status: :unbilled)

        delete bulk_destroy_time_entries_path, params: { ids: [entry.id] }

        expect(response).to redirect_to(time_entries_path)
        follow_redirect!
        expect(flash[:notice]).to eq("1 time entry deleted successfully.")
      end

      it "redirects with correct count message for multiple entries" do
        entry1 = create(:time_entry, status: :unbilled)
        entry2 = create(:time_entry, status: :unbilled)

        delete bulk_destroy_time_entries_path, params: { ids: [entry1.id, entry2.id] }

        expect(response).to redirect_to(time_entries_path)
        follow_redirect!
        expect(flash[:notice]).to eq("2 time entries deleted successfully.")
      end

      it "handles empty ids array" do
        delete bulk_destroy_time_entries_path, params: { ids: [] }

        expect(response).to redirect_to(time_entries_path)
        follow_redirect!
        expect(flash[:notice]).to eq("0 time entries deleted successfully.")
      end

      it "handles missing ids parameter" do
        delete bulk_destroy_time_entries_path

        expect(response).to redirect_to(time_entries_path)
        follow_redirect!
        expect(flash[:notice]).to eq("0 time entries deleted successfully.")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        entry = create(:time_entry)
        delete bulk_destroy_time_entries_path, params: { ids: [entry.id] }
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
