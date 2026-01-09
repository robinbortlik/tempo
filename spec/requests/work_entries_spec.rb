require 'rails_helper'

RSpec.describe WorkEntriesController, type: :request do
  let(:client) { create(:client, hourly_rate: 100, currency: "EUR") }
  let(:project) { create(:project, client: client, hourly_rate: 100) }

  before { sign_in }

  describe "entry type handling" do
    it "creates and returns entries with correct entry_type based on input" do
      # Test create with hours only -> time entry
      post work_entries_path, params: {
        work_entry: { project_id: project.id, date: Date.current, hours: 8, description: "Dev" }
      }
      expect(WorkEntry.last.entry_type).to eq("time")

      # Test create with amount only -> fixed entry
      post work_entries_path, params: {
        work_entry: { project_id: project.id, date: Date.current, amount: 500, description: "Logo" }
      }
      expect(WorkEntry.last.entry_type).to eq("fixed")

      # Test index returns both entry types
      get work_entries_path, headers: inertia_headers
      json = JSON.parse(response.body)
      entries = json['props']['date_groups'].flat_map { |g| g['entries'] }

      expect(entries.map { |e| e['entry_type'] }).to contain_exactly("time", "fixed")
    end
  end

  describe "filtering and summary" do
    it "filters by entry_type and returns correct summary stats" do
      create(:work_entry, :time_entry, project: project, hours: 8)
      create(:work_entry, :fixed_entry, project: project, amount: 500)

      # Test filtering
      get work_entries_path(entry_type: "fixed"), headers: inertia_headers
      json = JSON.parse(response.body)
      entries = json['props']['date_groups'].flat_map { |g| g['entries'] }
      expect(entries.length).to eq(1)
      expect(entries.first['entry_type']).to eq("fixed")

      # Test summary (without filter)
      get work_entries_path, headers: inertia_headers
      json = JSON.parse(response.body)
      summary = json['props']['summary']
      expect(summary['total_hours'].to_f).to eq(8.0)
      expect(summary['total_amount'].to_f).to eq(1300.0) # 8*100 + 500
    end
  end

  describe "hourly_rate handling" do
    it "permits hourly_rate in work_entry_params and auto-populates it" do
      post work_entries_path, params: {
        work_entry: { project_id: project.id, date: Date.current, hours: 8, description: "Dev", hourly_rate: 150 }
      }
      expect(WorkEntry.last.hourly_rate).to eq(150)
    end

    it "includes hourly_rate in work_entry_list_json response" do
      create(:work_entry, project: project, hours: 8, hourly_rate: 130)
      get work_entries_path, headers: inertia_headers
      json = JSON.parse(response.body)
      entries = json['props']['date_groups'].flat_map { |g| g['entries'] }
      expect(entries.first['hourly_rate'].to_f).to eq(130.0)
    end
  end

  describe "year/month URL structure" do
    let!(:entry_jan_2026) { create(:work_entry, project: project, date: Date.new(2026, 1, 15)) }
    let!(:entry_feb_2026) { create(:work_entry, project: project, date: Date.new(2026, 2, 10)) }
    let!(:entry_jan_2025) { create(:work_entry, project: project, date: Date.new(2025, 1, 20)) }

    it "defaults to current year with all months when no year/month params" do
      current_entry = create(:work_entry, project: project, date: Date.current)

      get work_entries_path, headers: inertia_headers
      json = JSON.parse(response.body)

      period = json['props']['period']
      expect(period['year']).to eq(Date.current.year)
      expect(period['month']).to be_nil # All months selected by default
    end

    it "filters by year only when year param provided without month" do
      get work_entries_path(year: 2026), headers: inertia_headers
      json = JSON.parse(response.body)

      entries = json['props']['date_groups'].flat_map { |g| g['entries'] }
      entry_ids = entries.map { |e| e['id'] }

      expect(entry_ids).to include(entry_jan_2026.id, entry_feb_2026.id)
      expect(entry_ids).not_to include(entry_jan_2025.id)

      period = json['props']['period']
      expect(period['year']).to eq(2026)
      expect(period['month']).to be_nil
    end

    it "filters by year and month when both params provided" do
      get work_entries_path(year: 2026, month: 1), headers: inertia_headers
      json = JSON.parse(response.body)

      entries = json['props']['date_groups'].flat_map { |g| g['entries'] }
      entry_ids = entries.map { |e| e['id'] }

      expect(entry_ids).to include(entry_jan_2026.id)
      expect(entry_ids).not_to include(entry_feb_2026.id, entry_jan_2025.id)

      period = json['props']['period']
      expect(period['year']).to eq(2026)
      expect(period['month']).to eq(1)
    end

    it "combines year/month filters with client_id filter" do
      other_client = create(:client)
      other_project = create(:project, client: other_client)
      other_entry = create(:work_entry, project: other_project, date: Date.new(2026, 1, 18))

      get work_entries_path(year: 2026, month: 1, client_id: client.id), headers: inertia_headers
      json = JSON.parse(response.body)

      entries = json['props']['date_groups'].flat_map { |g| g['entries'] }
      entry_ids = entries.map { |e| e['id'] }

      expect(entry_ids).to include(entry_jan_2026.id)
      expect(entry_ids).not_to include(other_entry.id)
    end

    it "includes available_years in period props" do
      get work_entries_path, headers: inertia_headers
      json = JSON.parse(response.body)

      available_years = json['props']['period']['available_years']

      expect(available_years).to include(2026, 2025, Date.current.year)
      expect(available_years).to eq(available_years.sort.reverse)
    end
  end

  private

  def inertia_headers
    { 'X-Inertia' => 'true', 'X-Inertia-Version' => ViteRuby.digest }
  end
end
