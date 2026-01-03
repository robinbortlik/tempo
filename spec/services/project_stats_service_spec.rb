require 'rails_helper'

RSpec.describe ProjectStatsService do
  describe "#stats" do
    let(:project) { create(:project, hourly_rate: 100) }
    let(:service) { described_class.new(project) }

    it "returns total_hours for all work entries" do
      create(:work_entry, project: project, hours: 8)
      create(:work_entry, project: project, hours: 4)

      expect(service.stats[:total_hours]).to eq(12.0)
    end

    it "returns unbilled_hours for unbilled entries only" do
      create(:work_entry, project: project, hours: 8, status: :unbilled)
      create(:work_entry, project: project, hours: 4, status: :invoiced)

      expect(service.stats[:unbilled_hours]).to eq(8.0)
    end

    it "returns unbilled_amount calculated from unbilled entries" do
      create(:work_entry, project: project, hours: 10, status: :unbilled)

      expect(service.stats[:unbilled_amount]).to eq(1000.0)
    end

    it "returns zero values when no entries exist" do
      stats = service.stats

      expect(stats[:total_hours]).to eq(0.0)
      expect(stats[:unbilled_hours]).to eq(0.0)
      expect(stats[:unbilled_amount]).to eq(0.0)
    end

    it "includes fixed entry amounts in unbilled_amount" do
      create(:work_entry, :fixed_entry, project: project, amount: 500, status: :unbilled)

      expect(service.stats[:unbilled_amount]).to eq(500.0)
    end
  end

  describe ".unbilled_hours_for_projects" do
    it "returns unbilled hours per project_id" do
      project1 = create(:project)
      project2 = create(:project)

      create(:work_entry, project: project1, hours: 8, status: :unbilled)
      create(:work_entry, project: project2, hours: 10, status: :unbilled)

      result = described_class.unbilled_hours_for_projects([project1.id, project2.id])

      expect(result[project1.id]).to eq(8.0)
      expect(result[project2.id]).to eq(10.0)
    end

    it "excludes invoiced entries" do
      project = create(:project)

      create(:work_entry, project: project, hours: 8, status: :unbilled)
      create(:work_entry, project: project, hours: 10, status: :invoiced)

      result = described_class.unbilled_hours_for_projects([project.id])

      expect(result[project.id]).to eq(8.0)
    end

    it "returns empty hash when given empty array" do
      expect(described_class.unbilled_hours_for_projects([])).to eq({})
    end

    it "returns nil for projects with no unbilled entries" do
      project = create(:project)
      create(:work_entry, project: project, hours: 8, status: :invoiced)

      result = described_class.unbilled_hours_for_projects([project.id])

      expect(result[project.id]).to be_nil
    end

    it "aggregates multiple entries for same project" do
      project = create(:project)

      create(:work_entry, project: project, hours: 8, status: :unbilled)
      create(:work_entry, project: project, hours: 4, status: :unbilled)

      result = described_class.unbilled_hours_for_projects([project.id])

      expect(result[project.id]).to eq(12.0)
    end
  end
end
