require 'rails_helper'

RSpec.describe SettingsSerializer do
  let(:settings) { Setting.instance }

  before do
    settings.update(
      company_name: "Test Company",
      address: "123 Test Street",
      email: "test@company.com",
      phone: "+1234567890",
      vat_id: "VAT123",
      company_registration: "REG123",
      bank_name: "Test Bank",
      bank_account: "1234567890",
      bank_swift: "TESTSWIFT",
      iban: "DE89370400440532013000",
      invoice_message: "Thank you!"
    )
  end

  describe "default serializer" do
    it "serializes all attributes" do
      result = described_class.new(settings).serializable_hash

      expect(result["company_name"]).to eq("Test Company")
      expect(result["address"]).to eq("123 Test Street")
      expect(result["email"]).to eq("test@company.com")
      expect(result["phone"]).to eq("+1234567890")
      expect(result["vat_id"]).to eq("VAT123")
      expect(result["company_registration"]).to eq("REG123")
      expect(result["bank_name"]).to eq("Test Bank")
      expect(result["bank_account"]).to eq("1234567890")
      expect(result["bank_swift"]).to eq("TESTSWIFT")
      expect(result["iban"]).to eq("DE89370400440532013000")
      expect(result["invoice_message"]).to eq("Thank you!")
    end

    context "without logo" do
      before do
        settings.logo.purge if settings.logo.attached?
      end

      it "returns nil for logo_url" do
        result = described_class.new(settings).serializable_hash

        expect(result["logo_url"]).to be_nil
      end
    end

    context "with logo" do
      let(:url_helpers) { double("url_helpers") }

      before do
        settings.logo.attach(
          io: StringIO.new("fake image"),
          filename: "logo.png",
          content_type: "image/png"
        )
        allow(url_helpers).to receive(:url_for).and_return("http://example.com/logo.png")
      end

      it "returns logo_url using url_helpers" do
        result = described_class.new(settings, params: { url_helpers: url_helpers }).serializable_hash

        expect(result["logo_url"]).to eq("http://example.com/logo.png")
      end
    end
  end

  describe SettingsSerializer::ForInvoice do
    it "serializes invoice-relevant attributes" do
      result = described_class.new(settings).serializable_hash

      expect(result["company_name"]).to eq("Test Company")
      expect(result["address"]).to eq("123 Test Street")
      expect(result["iban"]).to eq("DE89370400440532013000")
      expect(result["invoice_message"]).to eq("Thank you!")
    end

    it "excludes id" do
      result = described_class.new(settings).serializable_hash

      expect(result).not_to have_key("id")
    end
  end

  describe SettingsSerializer::ForReport do
    it "serializes only company_name" do
      result = described_class.new(settings).serializable_hash

      expect(result.keys).to contain_exactly("company_name")
      expect(result["company_name"]).to eq("Test Company")
    end
  end
end
