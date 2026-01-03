require 'rails_helper'

RSpec.describe WorkEntrySerializer do
  let(:client) { create(:client, name: "Test Client", currency: "EUR") }
  let(:project) { create(:project, client: client, name: "Test Project", hourly_rate: 100) }

  describe "default serializer" do
    let(:entry) { create(:work_entry, project: project, hours: 8, description: "Test work") }

    it "serializes basic attributes" do
      result = described_class.new(entry).serializable_hash

      expect(result["id"]).to eq(entry.id)
      expect(result["hours"]).to eq(8.0)
      expect(result["description"]).to eq("Test work")
      expect(result["status"]).to eq("unbilled")
    end

    it "includes project_name" do
      result = described_class.new(entry).serializable_hash

      expect(result["project_name"]).to eq("Test Project")
    end

    it "includes client_id and client_name" do
      result = described_class.new(entry).serializable_hash

      expect(result["client_id"]).to eq(client.id)
      expect(result["client_name"]).to eq("Test Client")
    end

    it "includes client_currency" do
      result = described_class.new(entry).serializable_hash

      expect(result["client_currency"]).to eq("EUR")
    end
  end

  describe WorkEntrySerializer::Recent do
    let(:entry) { create(:work_entry, project: project, hours: 4, description: "Recent work") }

    it "serializes recent entry attributes" do
      result = described_class.new(entry).serializable_hash

      expect(result["id"]).to eq(entry.id)
      expect(result["hours"]).to eq(4.0)
      expect(result["project_name"]).to eq("Test Project")
    end

    it "excludes client_id" do
      result = described_class.new(entry).serializable_hash

      expect(result).not_to have_key("client_id")
    end
  end

  describe WorkEntrySerializer::ForProjectShow do
    let(:entry) { create(:work_entry, project: project, hours: 8) }

    it "serializes entry for project show page" do
      result = described_class.new(entry).serializable_hash

      expect(result["id"]).to eq(entry.id)
      expect(result["hours"]).to eq(8.0)
      expect(result["calculated_amount"]).to be_a(Float)
    end

    it "includes date and description" do
      result = described_class.new(entry).serializable_hash

      expect(result).to include("date", "description", "status")
    end
  end

  describe WorkEntrySerializer::ForInvoice do
    let(:entry) { create(:work_entry, project: project, hours: 10, description: "Invoice work") }

    it "serializes entry for invoice" do
      result = described_class.new(entry).serializable_hash

      expect(result["id"]).to eq(entry.id)
      expect(result["hours"]).to eq(10.0)
      expect(result["project_name"]).to eq("Test Project")
      expect(result["effective_hourly_rate"]).to be_a(Float)
    end

    it "converts numeric values to floats" do
      result = described_class.new(entry).serializable_hash

      expect(result["hours"]).to be_a(Float)
      expect(result["calculated_amount"]).to be_a(Float)
    end
  end

  describe WorkEntrySerializer::ForInvoiceProjectGroup do
    let(:entry) { create(:work_entry, project: project, hours: 5) }

    it "serializes minimal entry data for project groups" do
      result = described_class.new(entry).serializable_hash

      expect(result["id"]).to eq(entry.id)
      expect(result["hours"]).to eq(5.0)
      expect(result).to include("date", "entry_type", "description")
    end

    it "excludes project_name" do
      result = described_class.new(entry).serializable_hash

      expect(result).not_to have_key("project_name")
    end
  end

  describe WorkEntrySerializer::GroupedByDate do
    let(:entry1) { create(:work_entry, :time_entry, project: project, hours: 8, date: Date.current) }
    let(:entry2) { create(:work_entry, :time_entry, project: project, hours: 4, date: Date.current) }

    it "serializes grouped entries" do
      data = {
        date: Date.current,
        formatted_date: "Today",
        entries: [entry1, entry2]
      }

      result = described_class.new(data).serializable_hash

      expect(result["date"]).to eq(Date.current)
      expect(result["formatted_date"]).to eq("Today")
      expect(result["total_hours"]).to eq(12.0)
    end

    it "calculates total_amount from entries" do
      data = {
        date: Date.current,
        formatted_date: "Today",
        entries: [entry1, entry2]
      }

      result = described_class.new(data).serializable_hash

      expect(result["total_amount"]).to eq(1200.0) # 12 hours * 100
    end

    it "includes serialized entries" do
      data = {
        date: Date.current,
        formatted_date: "Today",
        entries: [entry1]
      }

      result = described_class.new(data).serializable_hash

      expect(result["entries"]).to be_an(Array)
      expect(result["entries"].first["id"]).to eq(entry1.id)
    end
  end
end
