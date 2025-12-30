require 'rails_helper'

RSpec.describe ClientReportService do
  let(:client) { create(:client, hourly_rate: 100, currency: "EUR") }
  let(:project) { create(:project, client: client, name: "Project Alpha", hourly_rate: 100) }
  let(:project2) { create(:project, client: client, name: "Project Beta", hourly_rate: 150) }
  let(:current_year) { Date.current.year }
  let(:current_month) { Date.current.month }

  describe "#initialize" do
    it "accepts client, year, and month" do
      service = described_class.new(client: client, year: 2024, month: 12)

      expect(service.client).to eq(client)
      expect(service.year).to eq(2024)
      expect(service.month).to eq(12)
    end

    it "defaults to current year when year is not provided" do
      service = described_class.new(client: client)

      expect(service.year).to eq(current_year)
    end

    it "allows month to be nil for full year view" do
      service = described_class.new(client: client, year: 2024)

      expect(service.month).to be_nil
    end

    it "converts string parameters to integers" do
      service = described_class.new(client: client, year: "2024", month: "12")

      expect(service.year).to eq(2024)
      expect(service.month).to eq(12)
    end
  end

  describe "#unbilled_entries" do
    context "with month filter" do
      it "returns unbilled entries for the specified month" do
        entry1 = create(:time_entry, project: project, date: Date.new(2024, 12, 15), status: :unbilled)
        entry2 = create(:time_entry, project: project, date: Date.new(2024, 12, 20), status: :unbilled)
        # Entry outside month
        create(:time_entry, project: project, date: Date.new(2024, 11, 15), status: :unbilled)
        # Invoiced entry
        create(:time_entry, project: project, date: Date.new(2024, 12, 10), status: :invoiced)

        service = described_class.new(client: client, year: 2024, month: 12)

        expect(service.unbilled_entries).to contain_exactly(entry1, entry2)
      end
    end

    context "without month filter (full year)" do
      it "returns unbilled entries for the entire year" do
        entry1 = create(:time_entry, project: project, date: Date.new(2024, 1, 15), status: :unbilled)
        entry2 = create(:time_entry, project: project, date: Date.new(2024, 12, 20), status: :unbilled)
        # Entry from different year
        create(:time_entry, project: project, date: Date.new(2023, 6, 15), status: :unbilled)

        service = described_class.new(client: client, year: 2024)

        expect(service.unbilled_entries).to contain_exactly(entry1, entry2)
      end
    end

    it "excludes entries from other clients" do
      other_client = create(:client)
      other_project = create(:project, client: other_client)
      create(:time_entry, project: other_project, date: Date.new(2024, 12, 15), status: :unbilled)
      entry = create(:time_entry, project: project, date: Date.new(2024, 12, 15), status: :unbilled)

      service = described_class.new(client: client, year: 2024, month: 12)

      expect(service.unbilled_entries).to contain_exactly(entry)
    end

    it "returns entries ordered by date descending" do
      entry1 = create(:time_entry, project: project, date: Date.new(2024, 12, 10), status: :unbilled)
      entry2 = create(:time_entry, project: project, date: Date.new(2024, 12, 20), status: :unbilled)
      entry3 = create(:time_entry, project: project, date: Date.new(2024, 12, 15), status: :unbilled)

      service = described_class.new(client: client, year: 2024, month: 12)

      expect(service.unbilled_entries).to eq([entry2, entry3, entry1])
    end
  end

  describe "#invoiced_entries" do
    it "returns invoiced entries for the period" do
      entry1 = create(:time_entry, project: project, date: Date.new(2024, 12, 15), status: :invoiced)
      entry2 = create(:time_entry, project: project, date: Date.new(2024, 12, 20), status: :invoiced)
      # Unbilled entry
      create(:time_entry, project: project, date: Date.new(2024, 12, 10), status: :unbilled)

      service = described_class.new(client: client, year: 2024, month: 12)

      expect(service.invoiced_entries).to contain_exactly(entry1, entry2)
    end
  end

  describe "#unbilled_data" do
    before do
      create(:time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)
      create(:time_entry, project: project, date: Date.new(2024, 12, 16), hours: 4, status: :unbilled)
      create(:time_entry, project: project2, date: Date.new(2024, 12, 17), hours: 6, status: :unbilled)
    end

    let(:service) { described_class.new(client: client, year: 2024, month: 12) }

    it "returns total_hours" do
      expect(service.unbilled_data[:total_hours]).to eq(18)
    end

    it "returns total_amount" do
      # Project Alpha: (8 + 4) * 100 = 1200
      # Project Beta: 6 * 150 = 900
      # Total: 2100
      expect(service.unbilled_data[:total_amount]).to eq(2100)
    end

    it "groups entries by project" do
      project_groups = service.unbilled_data[:project_groups]

      expect(project_groups.length).to eq(2)
      expect(project_groups.map { |g| g[:project][:name] }).to contain_exactly("Project Alpha", "Project Beta")
    end

    it "includes project subtotals" do
      project_groups = service.unbilled_data[:project_groups]
      alpha_group = project_groups.find { |g| g[:project][:name] == "Project Alpha" }

      expect(alpha_group[:total_hours]).to eq(12)
      expect(alpha_group[:total_amount]).to eq(1200)
    end

    it "includes entry details" do
      project_groups = service.unbilled_data[:project_groups]
      alpha_group = project_groups.find { |g| g[:project][:name] == "Project Alpha" }

      expect(alpha_group[:entries].length).to eq(2)
      expect(alpha_group[:entries].first).to include(:id, :date, :hours, :description, :calculated_amount)
    end
  end

  describe "#invoiced_data" do
    before do
      @invoice = create(:invoice, client: client, status: :final,
                        period_start: Date.new(2024, 12, 1),
                        period_end: Date.new(2024, 12, 15),
                        total_hours: 20, total_amount: 2000)
      create(:time_entry, project: project, date: Date.new(2024, 12, 10), hours: 8, status: :invoiced)
      create(:time_entry, project: project, date: Date.new(2024, 12, 12), hours: 12, status: :invoiced)
    end

    let(:service) { described_class.new(client: client, year: 2024, month: 12) }

    it "returns total_hours" do
      expect(service.invoiced_data[:total_hours]).to eq(20)
    end

    it "returns total_amount" do
      expect(service.invoiced_data[:total_amount]).to eq(2000)
    end

    it "includes invoices in the period" do
      invoices = service.invoiced_data[:invoices]

      expect(invoices.length).to eq(1)
      expect(invoices.first[:number]).to eq(@invoice.number)
      expect(invoices.first[:total_amount]).to eq(2000)
    end

    it "excludes draft invoices" do
      create(:invoice, client: client, status: :draft,
             period_start: Date.new(2024, 12, 16),
             period_end: Date.new(2024, 12, 31))

      invoices = service.invoiced_data[:invoices]

      expect(invoices.length).to eq(1)
    end

    it "includes invoices that overlap with the period" do
      overlapping_invoice = create(:invoice, client: client, status: :final,
                                   period_start: Date.new(2024, 11, 15),
                                   period_end: Date.new(2024, 12, 5),
                                   total_hours: 10, total_amount: 1000)

      invoices = service.invoiced_data[:invoices]

      expect(invoices.map { |i| i[:id] }).to include(overlapping_invoice.id)
    end
  end

  describe "#report" do
    let(:service) { described_class.new(client: client, year: 2024, month: 12) }

    it "returns complete report structure" do
      report = service.report

      expect(report).to include(:client, :period, :unbilled, :invoiced)
    end

    it "includes client data" do
      report = service.report

      expect(report[:client][:id]).to eq(client.id)
      expect(report[:client][:name]).to eq(client.name)
      expect(report[:client][:currency]).to eq("EUR")
    end

    it "includes period data" do
      report = service.report

      expect(report[:period][:year]).to eq(2024)
      expect(report[:period][:month]).to eq(12)
      expect(report[:period][:available_years]).to include(current_year)
    end

    it "includes unbilled data" do
      create(:time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)

      report = service.report

      expect(report[:unbilled][:total_hours]).to eq(8)
      expect(report[:unbilled][:project_groups]).to be_an(Array)
    end

    it "includes invoiced data" do
      create(:time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :invoiced)

      report = service.report

      expect(report[:invoiced][:total_hours]).to eq(8)
      expect(report[:invoiced][:invoices]).to be_an(Array)
    end
  end

  describe "available_years in period_data" do
    it "includes years with time entries" do
      create(:time_entry, project: project, date: Date.new(2023, 6, 15), status: :unbilled)
      create(:time_entry, project: project, date: Date.new(2024, 12, 15), status: :unbilled)

      service = described_class.new(client: client)
      report = service.report

      expect(report[:period][:available_years]).to include(2023, 2024)
    end

    it "always includes current year" do
      service = described_class.new(client: client)
      report = service.report

      expect(report[:period][:available_years]).to include(current_year)
    end

    it "returns years in descending order" do
      create(:time_entry, project: project, date: Date.new(2022, 6, 15), status: :unbilled)
      create(:time_entry, project: project, date: Date.new(2023, 6, 15), status: :unbilled)

      service = described_class.new(client: client)
      years = service.report[:period][:available_years]

      expect(years).to eq(years.sort.reverse)
    end
  end

  describe "empty state handling" do
    let(:service) { described_class.new(client: client, year: 2024, month: 12) }

    it "returns empty arrays when no entries exist" do
      report = service.report

      expect(report[:unbilled][:project_groups]).to eq([])
      expect(report[:unbilled][:total_hours]).to eq(0)
      expect(report[:unbilled][:total_amount]).to eq(0)

      expect(report[:invoiced][:project_groups]).to eq([])
      expect(report[:invoiced][:total_hours]).to eq(0)
      expect(report[:invoiced][:total_amount]).to eq(0)
      expect(report[:invoiced][:invoices]).to eq([])
    end
  end
end
