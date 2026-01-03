require 'rails_helper'

RSpec.describe ClientSerializer do
  describe "default serializer" do
    let(:client) { create(:client, name: "Test Client", email: "test@example.com", currency: "EUR") }

    it "serializes basic attributes" do
      result = described_class.new(client).serializable_hash

      expect(result["id"]).to eq(client.id)
      expect(result["name"]).to eq("Test Client")
      expect(result["email"]).to eq("test@example.com")
      expect(result["currency"]).to eq("EUR")
    end

    it "includes all required fields" do
      result = described_class.new(client).serializable_hash

      expect(result.keys).to include(
        "id", "name", "address", "email", "contact_person", "vat_id",
        "company_registration", "bank_details", "payment_terms",
        "hourly_rate", "currency", "default_vat_rate",
        "share_token", "sharing_enabled"
      )
    end
  end

  describe ClientSerializer::List do
    let(:client) { create(:client, name: "Test Client", email: "test@example.com", hourly_rate: 100) }

    before do
      create(:project, client: client)
      create(:project, client: client)
    end

    it "serializes list attributes" do
      result = described_class.new(client).serializable_hash

      expect(result["id"]).to eq(client.id)
      expect(result["name"]).to eq("Test Client")
      expect(result["email"]).to eq("test@example.com")
    end

    it "includes projects_count" do
      result = described_class.new(client).serializable_hash

      expect(result["projects_count"]).to eq(2)
    end

    it "includes unbilled_hours from params" do
      unbilled_stats = { client.id => { hours: 10, amount: 1000 } }

      result = described_class.new(client, params: { unbilled_stats: unbilled_stats }).serializable_hash

      expect(result["unbilled_hours"]).to eq(10)
      expect(result["unbilled_amount"]).to eq(1000)
    end

    it "defaults to 0 when unbilled_stats not provided" do
      result = described_class.new(client).serializable_hash

      expect(result["unbilled_hours"]).to eq(0)
      expect(result["unbilled_amount"]).to eq(0)
    end

    it "serializes collection" do
      client2 = create(:client, name: "Client 2")

      result = described_class.new([ client, client2 ]).serializable_hash

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end
  end

  describe ClientSerializer::Empty do
    it "returns default values hash" do
      result = described_class.serializable_hash

      expect(result[:id]).to be_nil
      expect(result[:name]).to eq("")
      expect(result[:email]).to eq("")
    end

    it "responds to to_h" do
      result = described_class.to_h

      expect(result).to be_a(Hash)
      expect(result[:id]).to be_nil
    end
  end

  describe ClientSerializer::ForFilter do
    let(:client) { create(:client, name: "Filter Client") }

    it "serializes only id and name" do
      result = described_class.new(client).serializable_hash

      expect(result.keys).to contain_exactly("id", "name")
      expect(result["name"]).to eq("Filter Client")
    end
  end

  describe ClientSerializer::ForSelect do
    let(:client) { create(:client, name: "Select Client", hourly_rate: 150, currency: "USD") }

    it "serializes id, name, hourly_rate, and currency" do
      result = described_class.new(client).serializable_hash

      expect(result["id"]).to eq(client.id)
      expect(result["name"]).to eq("Select Client")
      expect(result["hourly_rate"]).to eq(150)
      expect(result["currency"]).to eq("USD")
    end
  end

  describe ClientSerializer::ForInvoiceSelect do
    let(:client) { create(:client, name: "Invoice Client", default_vat_rate: 21.0) }

    it "serializes required invoice fields" do
      result = described_class.new(client).serializable_hash

      expect(result["id"]).to eq(client.id)
      expect(result["name"]).to eq("Invoice Client")
      expect(result["default_vat_rate"]).to eq(21.0)
    end

    it "includes has_unbilled_entries from params" do
      unbilled_counts = { client.id => 5 }

      result = described_class.new(client, params: { unbilled_counts: unbilled_counts }).serializable_hash

      expect(result["has_unbilled_entries"]).to be true
    end

    it "returns false for has_unbilled_entries when count is 0" do
      unbilled_counts = { client.id => 0 }

      result = described_class.new(client, params: { unbilled_counts: unbilled_counts }).serializable_hash

      expect(result["has_unbilled_entries"]).to be false
    end
  end
end
