require 'rails_helper'

RSpec.describe ProjectSerializer do
  describe "default serializer" do
    let(:client) { create(:client, name: "Test Client", currency: "EUR") }
    let(:project) { create(:project, client: client, name: "Test Project", hourly_rate: 150) }

    it "serializes basic attributes" do
      result = described_class.new(project).serializable_hash

      expect(result["id"]).to eq(project.id)
      expect(result["name"]).to eq("Test Project")
      expect(result["hourly_rate"]).to eq(150)
      expect(result["active"]).to be true
    end

    it "includes client_name" do
      result = described_class.new(project).serializable_hash

      expect(result["client_name"]).to eq("Test Client")
    end

    it "includes client_currency" do
      result = described_class.new(project).serializable_hash

      expect(result["client_currency"]).to eq("EUR")
    end
  end

  describe ProjectSerializer::List do
    let(:project) { create(:project, hourly_rate: 100) }

    before do
      create(:work_entry, project: project, status: :unbilled)
      create(:work_entry, project: project, status: :invoiced)
    end

    it "serializes list attributes" do
      result = described_class.new(project).serializable_hash

      expect(result["id"]).to eq(project.id)
      expect(result["name"]).to eq(project.name)
    end

    it "includes work_entries_count" do
      result = described_class.new(project).serializable_hash

      expect(result["work_entries_count"]).to eq(2)
    end

    it "uses unbilled_stats from params when provided" do
      unbilled_stats = { project.id => 15.5 }

      result = described_class.new(project, params: { unbilled_stats: unbilled_stats }).serializable_hash

      expect(result["unbilled_hours"]).to eq(15.5)
    end
  end

  describe ProjectSerializer::Empty do
    it "returns default values hash" do
      result = described_class.serializable_hash

      expect(result[:id]).to be_nil
      expect(result[:name]).to eq("")
      expect(result[:client_id]).to be_nil
      expect(result[:active]).to be true
    end
  end

  describe ProjectSerializer::ForClientShow do
    let(:project) { create(:project, hourly_rate: 100) }

    before do
      create(:work_entry, :time_entry, project: project, hours: 8, status: :unbilled)
      create(:work_entry, :fixed_entry, project: project, amount: 500, status: :unbilled)
    end

    it "includes unbilled_hours for time entries only" do
      result = described_class.new(project).serializable_hash

      expect(result["unbilled_hours"]).to eq(8.0)
    end
  end

  describe ProjectSerializer::ForSelect do
    let(:project) { create(:project, name: "Select Project") }

    it "serializes id, name, and effective_hourly_rate" do
      result = described_class.new(project).serializable_hash

      expect(result.keys).to contain_exactly("id", "name", "effective_hourly_rate")
    end
  end

  describe ProjectSerializer::GroupedByClient do
    let(:client) { create(:client, name: "Group Client", currency: "EUR") }
    let(:project1) { create(:project, client: client, name: "Project 1", hourly_rate: 100) }
    let(:project2) { create(:project, client: client, name: "Project 2", hourly_rate: 150) }

    before do
      create(:work_entry, project: project1)
      create(:work_entry, project: project2)
    end

    it "serializes grouped data" do
      data = { client: client, projects: [project1, project2] }
      unbilled_stats = { project1.id => 10, project2.id => 5 }

      result = described_class.new(data, params: { unbilled_stats: unbilled_stats }).serializable_hash

      expect(result["client"][:id]).to eq(client.id)
      expect(result["client"][:name]).to eq("Group Client")
      expect(result["projects"].length).to eq(2)
    end

    it "includes unbilled_hours per project" do
      data = { client: client, projects: [project1] }
      unbilled_stats = { project1.id => 10 }

      result = described_class.new(data, params: { unbilled_stats: unbilled_stats }).serializable_hash

      expect(result["projects"].first[:unbilled_hours]).to eq(10)
    end
  end

  describe ProjectSerializer::GroupedByClientForForm do
    let(:client) { create(:client, name: "Form Client", currency: "USD") }
    let(:project) { create(:project, client: client, name: "Form Project") }

    it "serializes minimal project data for forms" do
      data = { client: client, projects: [project] }

      result = described_class.new(data).serializable_hash

      expect(result["client"][:name]).to eq("Form Client")
      expect(result["projects"].first[:id]).to eq(project.id)
      expect(result["projects"].first[:name]).to eq("Form Project")
    end
  end
end
