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

  private

  def inertia_headers
    { 'X-Inertia' => 'true', 'X-Inertia-Version' => ViteRuby.digest }
  end
end
