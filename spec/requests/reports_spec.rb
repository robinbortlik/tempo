require 'rails_helper'

RSpec.describe ReportsController, type: :request do
  let(:client) { create(:client, name: "Acme Corp", hourly_rate: 100, currency: "EUR") }
  let(:project) { create(:project, client: client, name: "Project Alpha", hourly_rate: 100) }

  describe "GET /reports/:share_token" do
    context "with valid share_token" do
      it "returns a successful response" do
        get report_path(client.share_token)
        expect(response).to have_http_status(:success)
      end

      it "renders the Reports/Show Inertia component" do
        get report_path(client.share_token)
        expect(response.body).to include('Reports/Show')
      end

      it "does not require authentication" do
        # No sign_in helper called - request should still succeed
        get report_path(client.share_token)
        expect(response).to have_http_status(:success)
      end

      it "returns client data" do
        get report_path(client.share_token), headers: inertia_headers

        json_response = JSON.parse(response.body)
        client_data = json_response['props']['client']

        expect(client_data['id']).to eq(client.id)
        expect(client_data['name']).to eq("Acme Corp")
        expect(client_data['currency']).to eq("EUR")
      end

      it "returns period data with current year by default" do
        get report_path(client.share_token), headers: inertia_headers

        json_response = JSON.parse(response.body)
        period = json_response['props']['period']

        expect(period['year']).to eq(Date.current.year)
        expect(period['month']).to be_nil
        expect(period['available_years']).to include(Date.current.year)
      end

      it "returns unbilled entries data" do
        create(:time_entry, project: project, date: Date.current, hours: 8, status: :unbilled)

        get report_path(client.share_token), headers: inertia_headers

        json_response = JSON.parse(response.body)
        unbilled = json_response['props']['unbilled']

        expect(unbilled['total_hours'].to_f).to eq(8.0)
        expect(unbilled['project_groups']).to be_an(Array)
      end

      it "returns invoiced entries data" do
        create(:time_entry, project: project, date: Date.current, hours: 4, status: :invoiced)

        get report_path(client.share_token), headers: inertia_headers

        json_response = JSON.parse(response.body)
        invoiced = json_response['props']['invoiced']

        expect(invoiced['total_hours'].to_f).to eq(4.0)
        expect(invoiced['invoices']).to be_an(Array)
      end
    end

    context "with year filter" do
      it "filters entries by year" do
        create(:time_entry, project: project, date: Date.new(2024, 6, 15), hours: 8, status: :unbilled)
        create(:time_entry, project: project, date: Date.new(2023, 6, 15), hours: 4, status: :unbilled)

        get report_path(client.share_token, year: 2024), headers: inertia_headers

        json_response = JSON.parse(response.body)
        period = json_response['props']['period']
        unbilled = json_response['props']['unbilled']

        expect(period['year']).to eq(2024)
        expect(unbilled['total_hours'].to_f).to eq(8.0)
      end
    end

    context "with month filter" do
      it "filters entries by month" do
        create(:time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)
        create(:time_entry, project: project, date: Date.new(2024, 11, 15), hours: 4, status: :unbilled)

        get report_path(client.share_token, year: 2024, month: 12), headers: inertia_headers

        json_response = JSON.parse(response.body)
        period = json_response['props']['period']
        unbilled = json_response['props']['unbilled']

        expect(period['year']).to eq(2024)
        expect(period['month']).to eq(12)
        expect(unbilled['total_hours'].to_f).to eq(8.0)
      end
    end

    context "with project groups" do
      it "groups entries by project with subtotals" do
        project2 = create(:project, client: client, name: "Project Beta", hourly_rate: 150)
        create(:time_entry, project: project, date: Date.current, hours: 8, status: :unbilled)
        create(:time_entry, project: project2, date: Date.current, hours: 4, status: :unbilled)

        get report_path(client.share_token), headers: inertia_headers

        json_response = JSON.parse(response.body)
        project_groups = json_response['props']['unbilled']['project_groups']

        expect(project_groups.length).to eq(2)

        alpha_group = project_groups.find { |g| g['project']['name'] == "Project Alpha" }
        expect(alpha_group['total_hours'].to_f).to eq(8.0)
        expect(alpha_group['total_amount'].to_f).to eq(800.0)
      end

      it "includes entry details in project groups" do
        entry = create(:time_entry, project: project, date: Date.current, hours: 8, description: "Test work", status: :unbilled)

        get report_path(client.share_token), headers: inertia_headers

        json_response = JSON.parse(response.body)
        project_groups = json_response['props']['unbilled']['project_groups']
        entries = project_groups.first['entries']

        expect(entries.length).to eq(1)
        expect(entries.first['id']).to eq(entry.id)
        expect(entries.first['hours'].to_f).to eq(8.0)
        expect(entries.first['description']).to eq("Test work")
      end
    end

    context "with invoices in period" do
      it "includes finalized invoices that overlap with the period" do
        invoice = create(:invoice, client: client, status: :final,
                        period_start: Date.current.beginning_of_year,
                        period_end: Date.current.end_of_year,
                        total_hours: 40, total_amount: 4000)

        get report_path(client.share_token), headers: inertia_headers

        json_response = JSON.parse(response.body)
        invoices = json_response['props']['invoiced']['invoices']

        expect(invoices.length).to eq(1)
        expect(invoices.first['id']).to eq(invoice.id)
        expect(invoices.first['number']).to eq(invoice.number)
      end
    end

    context "with invalid share_token" do
      it "returns 404 not found" do
        get report_path("invalid-token-here")
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for UUID-like but non-existent tokens" do
        fake_uuid = SecureRandom.uuid
        get report_path(fake_uuid)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "empty state" do
      it "returns empty arrays when client has no time entries" do
        get report_path(client.share_token), headers: inertia_headers

        json_response = JSON.parse(response.body)
        unbilled = json_response['props']['unbilled']
        invoiced = json_response['props']['invoiced']

        expect(unbilled['project_groups']).to eq([])
        expect(unbilled['total_hours'].to_f).to eq(0)
        expect(unbilled['total_amount'].to_f).to eq(0)

        expect(invoiced['project_groups']).to eq([])
        expect(invoiced['total_hours'].to_f).to eq(0)
        expect(invoiced['total_amount'].to_f).to eq(0)
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
