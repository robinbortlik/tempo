require 'rails_helper'

RSpec.describe ClientStatsService do
  describe "#stats" do
    let(:client) { create(:client, hourly_rate: 100) }
    let(:project) { create(:project, client: client, hourly_rate: 100) }
    let(:service) { described_class.new(client) }

    it "returns total_hours for all time entries" do
      create(:work_entry, project: project, hours: 8)
      create(:work_entry, project: project, hours: 4)

      expect(service.stats[:total_hours]).to eq(12.0)
    end

    it "returns total_invoiced from finalized invoices" do
      create(:invoice, :final, client: client, total_amount: 5000)
      create(:invoice, :final, client: client, total_amount: 3000)
      create(:invoice, :draft, client: client, total_amount: 2000)

      expect(service.stats[:total_invoiced]).to eq(8000.0)
    end

    it "returns unbilled_hours for unbilled time entries only" do
      create(:work_entry, project: project, hours: 8, status: :unbilled)
      create(:work_entry, project: project, hours: 4, status: :invoiced)

      expect(service.stats[:unbilled_hours]).to eq(8.0)
    end

    it "returns unbilled_amount calculated from unbilled entries" do
      create(:work_entry, project: project, hours: 10, status: :unbilled)

      expect(service.stats[:unbilled_amount]).to eq(1000.0)
    end

    it "excludes fixed entries from unbilled_hours" do
      create(:work_entry, :time_entry, project: project, hours: 8, status: :unbilled)
      create(:work_entry, :fixed_entry, project: project, amount: 500, status: :unbilled)

      expect(service.stats[:unbilled_hours]).to eq(8.0)
    end
  end

  describe ".unbilled_stats_for_clients" do
    it "returns a hash with hours and amount per client_id" do
      client1 = create(:client, hourly_rate: 100)
      client2 = create(:client, hourly_rate: 150)

      project1 = create(:project, client: client1, hourly_rate: 100)
      project2 = create(:project, client: client2, hourly_rate: 150)

      create(:work_entry, project: project1, hours: 8, status: :unbilled)
      create(:work_entry, project: project2, hours: 10, status: :unbilled)

      result = described_class.unbilled_stats_for_clients([ client1.id, client2.id ])

      expect(result[client1.id][:hours]).to eq(8.0)
      expect(result[client1.id][:amount]).to eq(800.0)
      expect(result[client2.id][:hours]).to eq(10.0)
      expect(result[client2.id][:amount]).to eq(1500.0)
    end

    it "returns zero values for clients with no unbilled entries" do
      client = create(:client)
      project = create(:project, client: client)
      create(:work_entry, project: project, hours: 8, status: :invoiced)

      result = described_class.unbilled_stats_for_clients([ client.id ])

      expect(result[client.id][:hours]).to eq(0)
      expect(result[client.id][:amount]).to eq(0)
    end

    it "returns empty hash when given empty array" do
      expect(described_class.unbilled_stats_for_clients([])).to eq({})
    end

    it "excludes invoiced entries from stats" do
      client = create(:client, hourly_rate: 100)
      project = create(:project, client: client, hourly_rate: 100)

      create(:work_entry, project: project, hours: 8, status: :unbilled)
      create(:work_entry, project: project, hours: 10, status: :invoiced)

      result = described_class.unbilled_stats_for_clients([ client.id ])

      expect(result[client.id][:hours]).to eq(8.0)
      expect(result[client.id][:amount]).to eq(800.0)
    end

    it "aggregates entries from multiple projects for same client" do
      client = create(:client, hourly_rate: 100)
      project1 = create(:project, client: client, hourly_rate: 100)
      project2 = create(:project, client: client, hourly_rate: 150)

      create(:work_entry, project: project1, hours: 8, status: :unbilled)
      create(:work_entry, project: project2, hours: 4, status: :unbilled)

      result = described_class.unbilled_stats_for_clients([ client.id ])

      expect(result[client.id][:hours]).to eq(12.0)
      expect(result[client.id][:amount]).to eq(1400.0)
    end
  end

  describe ".unbilled_counts_for_clients" do
    it "returns count of unbilled entries per client" do
      client1 = create(:client)
      client2 = create(:client)

      project1 = create(:project, client: client1)
      project2 = create(:project, client: client2)

      create(:work_entry, project: project1, status: :unbilled)
      create(:work_entry, project: project1, status: :unbilled)
      create(:work_entry, project: project2, status: :unbilled)

      result = described_class.unbilled_counts_for_clients([ client1.id, client2.id ])

      expect(result[client1.id]).to eq(2)
      expect(result[client2.id]).to eq(1)
    end

    it "excludes invoiced entries from count" do
      client = create(:client)
      project = create(:project, client: client)

      create(:work_entry, project: project, status: :unbilled)
      create(:work_entry, project: project, status: :invoiced)

      result = described_class.unbilled_counts_for_clients([ client.id ])

      expect(result[client.id]).to eq(1)
    end

    it "returns empty hash when given empty array" do
      expect(described_class.unbilled_counts_for_clients([])).to eq({})
    end

    it "returns nil for clients with no unbilled entries" do
      client = create(:client)
      project = create(:project, client: client)
      create(:work_entry, project: project, status: :invoiced)

      result = described_class.unbilled_counts_for_clients([ client.id ])

      expect(result[client.id]).to be_nil
    end
  end
end
