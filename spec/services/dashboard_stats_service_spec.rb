require 'rails_helper'

RSpec.describe DashboardStatsService do
  let(:service) { described_class.new }

  describe "#hours_this_week" do
    it "returns total hours for the current week" do
      project = create(:project)
      # Entry this week
      create(:work_entry, project: project, date: Date.current, hours: 8)
      create(:work_entry, project: project, date: Date.current.beginning_of_week, hours: 4)
      # Entry last week (should be excluded)
      create(:work_entry, project: project, date: 1.week.ago, hours: 10)

      expect(service.hours_this_week).to eq(12.0)
    end

    it "returns 0 when no entries exist this week" do
      project = create(:project)
      create(:work_entry, project: project, date: 1.week.ago, hours: 8)

      expect(service.hours_this_week).to eq(0.0)
    end
  end

  describe "#hours_this_month" do
    it "returns total hours for the current month" do
      project = create(:project)
      # Entries this month
      create(:work_entry, project: project, date: Date.current.beginning_of_month, hours: 8)
      create(:work_entry, project: project, date: Date.current, hours: 4)
      # Entry last month (should be excluded)
      create(:work_entry, project: project, date: 1.month.ago, hours: 10)

      expect(service.hours_this_month).to eq(12.0)
    end

    it "returns 0 when no entries exist this month" do
      project = create(:project)
      create(:work_entry, project: project, date: 1.month.ago, hours: 8)

      expect(service.hours_this_month).to eq(0.0)
    end
  end

  describe "#unbilled_hours" do
    it "returns total unbilled hours across all clients" do
      project1 = create(:project)
      project2 = create(:project)

      create(:work_entry, project: project1, hours: 8, status: :unbilled)
      create(:work_entry, project: project2, hours: 4, status: :unbilled)
      create(:work_entry, project: project1, hours: 10, status: :invoiced)

      expect(service.unbilled_hours).to eq(12.0)
    end

    it "returns 0 when all entries are invoiced" do
      project = create(:project)
      create(:work_entry, project: project, hours: 8, status: :invoiced)

      expect(service.unbilled_hours).to eq(0.0)
    end
  end

  describe "#unbilled_amounts_by_currency" do
    it "returns unbilled amounts grouped by currency" do
      eur_client = create(:client, currency: "EUR", hourly_rate: 100)
      usd_client = create(:client, currency: "USD", hourly_rate: 150)

      eur_project = create(:project, client: eur_client, hourly_rate: 100)
      usd_project = create(:project, client: usd_client, hourly_rate: 150)

      create(:work_entry, project: eur_project, hours: 8, status: :unbilled) # 800 EUR
      create(:work_entry, project: eur_project, hours: 4, status: :unbilled) # 400 EUR
      create(:work_entry, project: usd_project, hours: 10, status: :unbilled) # 1500 USD

      result = service.unbilled_amounts_by_currency

      expect(result["EUR"]).to eq(1200.0)
      expect(result["USD"]).to eq(1500.0)
    end

    it "defaults to EUR when client has no currency set" do
      client = create(:client, :minimal, name: "Test Client", currency: nil, hourly_rate: 100)
      project = create(:project, client: client, hourly_rate: 100)
      create(:work_entry, project: project, hours: 8, status: :unbilled)

      result = service.unbilled_amounts_by_currency

      expect(result["EUR"]).to eq(800.0)
    end

    it "returns empty hash when no unbilled entries exist" do
      expect(service.unbilled_amounts_by_currency).to eq({})
    end

    it "excludes invoiced entries" do
      client = create(:client, currency: "EUR", hourly_rate: 100)
      project = create(:project, client: client, hourly_rate: 100)

      create(:work_entry, project: project, hours: 8, status: :unbilled)
      create(:work_entry, project: project, hours: 10, status: :invoiced)

      result = service.unbilled_amounts_by_currency

      expect(result["EUR"]).to eq(800.0)
    end
  end

  describe "#unbilled_by_client" do
    it "returns unbilled breakdown per client" do
      client1 = create(:client, name: "Client A", currency: "EUR", hourly_rate: 100)
      client2 = create(:client, name: "Client B", currency: "USD", hourly_rate: 150)

      project1 = create(:project, client: client1, hourly_rate: 100)
      project2 = create(:project, client: client2, hourly_rate: 150)

      create(:work_entry, project: project1, hours: 8, status: :unbilled)
      create(:work_entry, project: project2, hours: 10, status: :unbilled)

      result = service.unbilled_by_client

      expect(result.length).to eq(2)

      client_b_data = result.find { |c| c[:name] == "Client B" }
      expect(client_b_data[:currency]).to eq("USD")
      expect(client_b_data[:total_hours]).to eq(10.0)
      expect(client_b_data[:total_amount]).to eq(1500.0)
      expect(client_b_data[:project_count]).to eq(1)
    end

    it "sorts clients by total amount descending" do
      client1 = create(:client, name: "Small Client", currency: "EUR", hourly_rate: 50)
      client2 = create(:client, name: "Big Client", currency: "EUR", hourly_rate: 200)

      project1 = create(:project, client: client1, hourly_rate: 50)
      project2 = create(:project, client: client2, hourly_rate: 200)

      create(:work_entry, project: project1, hours: 8, status: :unbilled) # 400
      create(:work_entry, project: project2, hours: 8, status: :unbilled) # 1600

      result = service.unbilled_by_client

      expect(result.first[:name]).to eq("Big Client")
      expect(result.last[:name]).to eq("Small Client")
    end

    it "calculates average rate correctly" do
      client = create(:client, currency: "EUR", hourly_rate: 100)
      project1 = create(:project, client: client, hourly_rate: 100)
      project2 = create(:project, client: client, hourly_rate: 150)

      create(:work_entry, project: project1, hours: 10, status: :unbilled) # 1000
      create(:work_entry, project: project2, hours: 10, status: :unbilled) # 1500

      result = service.unbilled_by_client.first

      # Average rate = 2500 / 20 = 125
      expect(result[:average_rate]).to eq(125.0)
    end

    it "counts distinct projects with unbilled entries" do
      client = create(:client, currency: "EUR", hourly_rate: 100)
      project1 = create(:project, client: client, hourly_rate: 100)
      project2 = create(:project, client: client, hourly_rate: 100)
      project3 = create(:project, client: client, hourly_rate: 100)

      create(:work_entry, project: project1, hours: 4, status: :unbilled)
      create(:work_entry, project: project1, hours: 4, status: :unbilled)
      create(:work_entry, project: project2, hours: 8, status: :unbilled)
      # project3 has no unbilled entries
      create(:work_entry, project: project3, hours: 8, status: :invoiced)

      result = service.unbilled_by_client.first

      expect(result[:project_count]).to eq(2)
    end

    it "excludes clients with no unbilled entries" do
      client1 = create(:client, name: "Has Unbilled")
      client2 = create(:client, name: "All Invoiced")

      project1 = create(:project, client: client1)
      project2 = create(:project, client: client2)

      create(:work_entry, project: project1, hours: 8, status: :unbilled)
      create(:work_entry, project: project2, hours: 8, status: :invoiced)

      result = service.unbilled_by_client

      expect(result.length).to eq(1)
      expect(result.first[:name]).to eq("Has Unbilled")
    end
  end

  describe "#time_by_client" do
    it "returns hours grouped by client for all time entries" do
      client1 = create(:client, name: "Client A")
      client2 = create(:client, name: "Client B")

      project1 = create(:project, client: client1)
      project2 = create(:project, client: client2)

      create(:work_entry, project: project1, hours: 8)
      create(:work_entry, project: project1, hours: 4)
      create(:work_entry, project: project2, hours: 10)

      result = service.time_by_client

      expect(result.length).to eq(2)

      client_a_data = result.find { |c| c[:name] == "Client A" }
      expect(client_a_data[:hours]).to eq(12.0)

      client_b_data = result.find { |c| c[:name] == "Client B" }
      expect(client_b_data[:hours]).to eq(10.0)
    end

    it "sorts by hours descending" do
      client1 = create(:client, name: "Less Hours")
      client2 = create(:client, name: "More Hours")

      project1 = create(:project, client: client1)
      project2 = create(:project, client: client2)

      create(:work_entry, project: project1, hours: 5)
      create(:work_entry, project: project2, hours: 20)

      result = service.time_by_client

      expect(result.first[:name]).to eq("More Hours")
    end
  end

  describe "#time_by_project" do
    it "returns hours grouped by project" do
      project1 = create(:project, name: "Project A")
      project2 = create(:project, name: "Project B")

      create(:work_entry, project: project1, hours: 8)
      create(:work_entry, project: project2, hours: 12)

      result = service.time_by_project

      project_a_data = result.find { |p| p[:name] == "Project A" }
      expect(project_a_data[:hours]).to eq(8.0)
    end

    it "limits to top 10 projects" do
      12.times do |i|
        project = create(:project, name: "Project #{i}")
        create(:work_entry, project: project, hours: i + 1)
      end

      result = service.time_by_project

      expect(result.length).to eq(10)
    end

    it "sorts by hours descending" do
      project1 = create(:project, name: "Small Project")
      project2 = create(:project, name: "Big Project")

      create(:work_entry, project: project1, hours: 5)
      create(:work_entry, project: project2, hours: 50)

      result = service.time_by_project

      expect(result.first[:name]).to eq("Big Project")
    end
  end

  describe "#earnings_over_time" do
    it "returns monthly earnings from finalized invoices" do
      client = create(:client, currency: "EUR")

      # Last month
      create(:invoice, client: client, status: :final,
        issue_date: 1.month.ago.to_date,
        total_amount: 5000)

      # This month
      create(:invoice, client: client, status: :final,
        issue_date: Date.current,
        total_amount: 3000)

      result = service.earnings_over_time(months: 3)

      expect(result.length).to eq(3)
      this_month_data = result.last
      expect(this_month_data[:amount]).to eq(3000.0)
    end

    it "excludes draft invoices" do
      client = create(:client)
      create(:invoice, client: client, status: :draft,
        issue_date: Date.current,
        total_amount: 5000)

      result = service.earnings_over_time(months: 1)

      expect(result.first[:amount]).to eq(0)
    end

    it "fills missing months with zero" do
      result = service.earnings_over_time(months: 3)

      expect(result.length).to eq(3)
      expect(result.all? { |m| m[:amount] == 0 }).to be true
    end
  end

  describe "#hours_trend" do
    it "returns monthly hours logged" do
      project = create(:project)

      create(:work_entry, project: project, date: 1.month.ago.to_date, hours: 40)
      create(:work_entry, project: project, date: Date.current, hours: 32)

      result = service.hours_trend(months: 3)

      expect(result.length).to eq(3)
      this_month_data = result.last
      expect(this_month_data[:hours]).to eq(32.0)
    end

    it "fills missing months with zero" do
      result = service.hours_trend(months: 3)

      expect(result.length).to eq(3)
      expect(result.all? { |m| m[:hours] == 0 }).to be true
    end
  end

  describe "#stats" do
    it "returns all stats in a single hash" do
      result = service.stats

      expect(result).to have_key(:hours_this_week)
      expect(result).to have_key(:hours_this_month)
      expect(result).to have_key(:unbilled_hours)
      expect(result).to have_key(:unbilled_amounts)
      expect(result).to have_key(:unbilled_by_client)
    end
  end
end
