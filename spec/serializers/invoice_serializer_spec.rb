require 'rails_helper'

RSpec.describe InvoiceSerializer do
  let(:client) { create(:client, name: "Test Client", address: "123 Street", email: "client@test.com") }
  let(:invoice) { create(:invoice, client: client, number: "2024-001", total_hours: 40, total_amount: 4000) }

  describe "default serializer" do
    it "serializes basic attributes" do
      result = described_class.new(invoice).serializable_hash

      expect(result["id"]).to eq(invoice.id)
      expect(result["number"]).to eq("2024-001")
      expect(result["status"]).to eq("draft")
    end

    it "converts numeric values to floats" do
      result = described_class.new(invoice).serializable_hash

      expect(result["total_hours"]).to be_a(Float)
      expect(result["total_amount"]).to be_a(Float)
      expect(result["subtotal"]).to be_a(Float)
      expect(result["total_vat"]).to be_a(Float)
      expect(result["grand_total"]).to be_a(Float)
    end

    it "includes client_name and client_address" do
      result = described_class.new(invoice).serializable_hash

      expect(result["client_name"]).to eq("Test Client")
      expect(result["client_address"]).to eq("123 Street")
      expect(result["client_email"]).to eq("client@test.com")
    end

    it "includes vat_totals_by_rate" do
      result = described_class.new(invoice).serializable_hash

      expect(result["vat_totals_by_rate"]).to be_a(Hash)
    end
  end

  describe InvoiceSerializer::List do
    it "serializes list attributes" do
      result = described_class.new(invoice).serializable_hash

      expect(result["id"]).to eq(invoice.id)
      expect(result["number"]).to eq("2024-001")
      expect(result["client_name"]).to eq("Test Client")
    end

    it "excludes detailed client info" do
      result = described_class.new(invoice).serializable_hash

      expect(result).not_to have_key("client_address")
      expect(result).not_to have_key("client_email")
    end

    it "serializes collection" do
      invoice2 = create(:invoice, client: client)

      result = described_class.new([ invoice, invoice2 ]).serializable_hash

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end
  end

  describe InvoiceSerializer::ProjectGroup do
    let(:project) { create(:project, client: client, name: "Test Project", hourly_rate: 100) }
    let(:entry1) { create(:work_entry, :time_entry, project: project, hours: 8) }
    let(:entry2) { create(:work_entry, :time_entry, project: project, hours: 4) }

    it "serializes project group data" do
      data = { project: project, entries: [ entry1, entry2 ] }

      result = described_class.new(data).serializable_hash

      expect(result["project"][:id]).to eq(project.id)
      expect(result["project"][:name]).to eq("Test Project")
    end

    it "calculates total_hours from time entries" do
      data = { project: project, entries: [ entry1, entry2 ] }

      result = described_class.new(data).serializable_hash

      expect(result["total_hours"]).to eq(12.0)
    end

    it "calculates total_amount from all entries" do
      data = { project: project, entries: [ entry1, entry2 ] }

      result = described_class.new(data).serializable_hash

      expect(result["total_amount"]).to eq(1200.0)
    end

    it "serializes entries using ForInvoiceProjectGroup" do
      data = { project: project, entries: [ entry1 ] }

      result = described_class.new(data).serializable_hash

      expect(result["entries"]).to be_an(Array)
      expect(result["entries"].first["id"]).to eq(entry1.id)
    end
  end
end
