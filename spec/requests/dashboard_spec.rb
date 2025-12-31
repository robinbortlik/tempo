require 'rails_helper'

RSpec.describe DashboardController, type: :request do
  describe "GET /dashboard" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end

      it "renders the Dashboard/Index Inertia component" do
        get dashboard_path
        expect(response.body).to include('Dashboard/Index')
      end

      it "returns stats data" do
        get dashboard_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        stats = json_response['props']['stats']

        expect(stats).to have_key('hours_this_week')
        expect(stats).to have_key('hours_this_month')
        expect(stats).to have_key('unbilled_hours')
        expect(stats).to have_key('unbilled_amounts')
        expect(stats).to have_key('unbilled_by_client')
      end

      it "returns charts data" do
        get dashboard_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        charts = json_response['props']['charts']

        expect(charts).to have_key('time_by_client')
        expect(charts).to have_key('time_by_project')
        expect(charts).to have_key('earnings_over_time')
        expect(charts).to have_key('hours_trend')
      end

      context "with time entry data" do
        let(:client) { create(:client, currency: "EUR", hourly_rate: 100) }
        let(:project) { create(:project, client: client, hourly_rate: 100) }

        before do
          create(:work_entry, project: project, date: Date.current, hours: 8, status: :unbilled)
        end

        it "returns correct hours_this_week" do
          get dashboard_path, headers: inertia_headers

          json_response = JSON.parse(response.body)
          expect(json_response['props']['stats']['hours_this_week']).to eq(8.0)
        end

        it "returns unbilled amounts by currency" do
          get dashboard_path, headers: inertia_headers

          json_response = JSON.parse(response.body)
          unbilled_amounts = json_response['props']['stats']['unbilled_amounts']

          expect(unbilled_amounts['EUR'].to_f).to eq(800.0)
        end

        it "returns unbilled by client" do
          get dashboard_path, headers: inertia_headers

          json_response = JSON.parse(response.body)
          unbilled_by_client = json_response['props']['stats']['unbilled_by_client']

          expect(unbilled_by_client.length).to eq(1)
          expect(unbilled_by_client.first['name']).to eq(client.name)
          expect(unbilled_by_client.first['total_hours']).to eq(8.0)
          expect(unbilled_by_client.first['total_amount']).to eq(800.0)
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get dashboard_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /dashboard/time_by_client" do
    context "when authenticated" do
      before { sign_in }

      it "returns JSON data" do
        client = create(:client, name: "Test Client")
        project = create(:project, client: client)
        create(:work_entry, project: project, hours: 8)

        get time_by_client_dashboard_path, as: :json

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")

        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.first['name']).to eq("Test Client")
        expect(json_response.first['hours']).to eq(8.0)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get time_by_client_dashboard_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /dashboard/time_by_project" do
    context "when authenticated" do
      before { sign_in }

      it "returns JSON data" do
        project = create(:project, name: "Test Project")
        create(:work_entry, project: project, hours: 10)

        get time_by_project_dashboard_path, as: :json

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.first['name']).to eq("Test Project")
        expect(json_response.first['hours']).to eq(10.0)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get time_by_project_dashboard_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /dashboard/earnings_over_time" do
    context "when authenticated" do
      before { sign_in }

      it "returns JSON data with monthly earnings" do
        client = create(:client)
        create(:invoice, client: client, status: :final,
          issue_date: Date.current, total_amount: 5000)

        get earnings_over_time_dashboard_path, as: :json

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.last['amount']).to eq(5000.0)
      end

      it "accepts months parameter" do
        get earnings_over_time_dashboard_path(months: 6), as: :json

        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(6)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get earnings_over_time_dashboard_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /dashboard/hours_trend" do
    context "when authenticated" do
      before { sign_in }

      it "returns JSON data with monthly hours" do
        project = create(:project)
        create(:work_entry, project: project, date: Date.current, hours: 40)

        get hours_trend_dashboard_path, as: :json

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.last['hours']).to eq(40.0)
      end

      it "accepts months parameter" do
        get hours_trend_dashboard_path(months: 6), as: :json

        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(6)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get hours_trend_dashboard_path
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
