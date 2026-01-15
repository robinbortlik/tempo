require 'rails_helper'

RSpec.describe PaymentQrCodeGenerator do
  let(:client) { create(:client, currency: "EUR") }
  let(:invoice) { create(:invoice, client: client, currency: "EUR") }
  let(:settings) { build(:setting, iban: "DE89370400440532013000", bank_swift: "COBADEFFXXX", company_name: "Test Company") }

  before do
    # Set up grand_total by creating line items
    invoice.line_items.create!(
      line_type: :fixed,
      description: "Test item",
      amount: 1000.00,
      vat_rate: 0,
      position: 0
    )
  end

  subject(:generator) { described_class.new(invoice: invoice, settings: settings) }

  describe "#available?" do
    context "with EUR currency and IBAN" do
      it "returns true" do
        expect(generator.available?).to be true
      end
    end

    context "with CZK currency and IBAN" do
      let(:client) { create(:client, currency: "CZK") }
      let(:invoice) { create(:invoice, client: client, currency: "CZK") }
      let(:settings) { build(:setting, iban: "CZ6508000000192000145399", bank_swift: "GIBACZPX") }

      it "returns true" do
        expect(generator.available?).to be true
      end
    end

    context "without IBAN" do
      let(:settings) { build(:setting, iban: nil) }

      it "returns false" do
        expect(generator.available?).to be false
      end
    end

    context "with empty IBAN" do
      let(:settings) { build(:setting, iban: "") }

      it "returns false" do
        expect(generator.available?).to be false
      end
    end

    context "with USD currency" do
      let(:client) { create(:client, currency: "USD") }
      let(:invoice) { create(:invoice, :usd, client: client) }

      it "returns false" do
        expect(generator.available?).to be false
      end
    end

    context "with GBP currency" do
      let(:client) { create(:client, currency: "GBP") }
      let(:invoice) { create(:invoice, :gbp, client: client) }

      it "returns false" do
        expect(generator.available?).to be false
      end
    end

    context "with zero amount invoice" do
      before do
        invoice.line_items.destroy_all
      end

      it "returns false" do
        expect(generator.available?).to be false
      end
    end
  end

  describe "#format" do
    context "with EUR currency" do
      it "returns :epc" do
        expect(generator.format).to eq(:epc)
      end
    end

    context "with CZK currency" do
      let(:client) { create(:client, currency: "CZK") }
      let(:invoice) { create(:invoice, client: client, currency: "CZK") }
      let(:settings) { build(:setting, iban: "CZ6508000000192000145399") }

      it "returns :spayd" do
        expect(generator.format).to eq(:spayd)
      end
    end

    context "when not available" do
      let(:settings) { build(:setting, iban: nil) }

      it "returns nil" do
        expect(generator.format).to be_nil
      end
    end
  end

  describe "#to_data_url" do
    context "with EUR currency (EPC format)" do
      it "returns a valid data URL" do
        result = generator.to_data_url
        expect(result).to start_with("data:image/svg+xml;base64,")
      end

      it "generates valid base64-encoded SVG" do
        result = generator.to_data_url
        base64_content = result.sub("data:image/svg+xml;base64,", "")
        decoded = Base64.decode64(base64_content)
        expect(decoded).to include("<svg")
        expect(decoded).to include("</svg>")
      end

      it "encodes EPC payload correctly" do
        # Access private method to verify payload structure
        payload = generator.send(:build_epc_payload)

        expect(payload).to include("BCD")
        expect(payload).to include("002")
        expect(payload).to include("SCT")
        expect(payload).to include("COBADEFFXXX")
        expect(payload).to include("Test Company")
        expect(payload).to include("DE89370400440532013000")
        expect(payload).to include("EUR1000.00")
        expect(payload).to include(invoice.number)
      end
    end

    context "with EUR and missing BIC" do
      let(:settings) { build(:setting, iban: "DE89370400440532013000", bank_swift: nil, company_name: "Test Company") }

      it "still generates valid EPC payload" do
        payload = generator.send(:build_epc_payload)
        lines = payload.split("\n")

        expect(lines[0]).to eq("BCD")
        expect(lines[4]).to eq("") # BIC line should be empty
        expect(lines[5]).to eq("Test Company")
      end

      it "returns a valid data URL" do
        expect(generator.to_data_url).to start_with("data:image/svg+xml;base64,")
      end
    end

    context "with CZK currency (SPAYD format)" do
      let(:client) { create(:client, currency: "CZK") }
      let(:invoice) { create(:invoice, client: client, currency: "CZK", number: "2024-001") }
      let(:settings) { build(:setting, iban: "CZ6508000000192000145399", bank_swift: "GIBACZPX") }

      before do
        invoice.line_items.destroy_all
        invoice.line_items.create!(
          line_type: :fixed,
          description: "Test item",
          amount: 5000.00,
          vat_rate: 0,
          position: 0
        )
      end

      it "returns a valid data URL" do
        result = generator.to_data_url
        expect(result).to start_with("data:image/svg+xml;base64,")
      end

      it "encodes SPAYD payload correctly" do
        payload = generator.send(:build_spayd_payload)

        expect(payload).to include("SPD*1.0")
        expect(payload).to include("ACC:CZ6508000000192000145399+GIBACZPX")
        expect(payload).to include("AM:5000.00")
        expect(payload).to include("CC:CZK")
        expect(payload).to include("MSG:2024-001")
        expect(payload).to include("X-VS:2024001")
      end
    end

    context "with SPAYD and missing BIC" do
      let(:client) { create(:client, currency: "CZK") }
      let(:invoice) { create(:invoice, client: client, currency: "CZK") }
      let(:settings) { build(:setting, iban: "CZ6508000000192000145399", bank_swift: nil) }

      before do
        invoice.line_items.create!(
          line_type: :fixed,
          description: "Test item",
          amount: 1000.00,
          vat_rate: 0,
          position: 0
        )
      end

      it "generates SPAYD without BIC suffix" do
        payload = generator.send(:build_spayd_payload)
        expect(payload).to include("ACC:CZ6508000000192000145399*")
        expect(payload).not_to include("+")
      end
    end

    context "when not available" do
      let(:settings) { build(:setting, iban: nil) }

      it "returns nil" do
        expect(generator.to_data_url).to be_nil
      end
    end
  end

  describe "payload sanitization" do
    context "with IBAN containing spaces" do
      let(:settings) { build(:setting, iban: "DE89 3704 0044 0532 0130 00", bank_swift: "COBADEFFXXX", company_name: "Test") }

      it "removes spaces from IBAN" do
        payload = generator.send(:build_epc_payload)
        expect(payload).to include("DE89370400440532013000")
        expect(payload).not_to include("DE89 3704")
      end
    end

    context "with long company name" do
      let(:settings) { build(:setting, iban: "DE89370400440532013000", company_name: "A" * 100) }

      it "truncates company name to 70 characters" do
        payload = generator.send(:build_epc_payload)
        lines = payload.split("\n")
        expect(lines[5].length).to eq(70)
      end
    end
  end

  describe "bank_account parameter" do
    let(:bank_account) { create(:bank_account, iban: "CZ6508000000192000145399", bank_swift: "GIBACZPX") }
    let(:settings) { build(:setting, company_name: "Test Company") }
    let(:client) { create(:client, currency: "EUR") }
    let(:invoice) { create(:invoice, client: client, currency: "EUR") }

    before do
      invoice.line_items.create!(
        line_type: :fixed,
        description: "Test item",
        amount: 1000.00,
        vat_rate: 0,
        position: 0
      )
    end

    subject(:generator_with_bank_account) do
      described_class.new(invoice: invoice, settings: settings, bank_account: bank_account)
    end

    it "uses bank_account IBAN for QR code generation" do
      payload = generator_with_bank_account.send(:build_epc_payload)
      expect(payload).to include("CZ6508000000192000145399")
    end

    it "uses bank_account BIC for QR code generation" do
      payload = generator_with_bank_account.send(:build_epc_payload)
      expect(payload).to include("GIBACZPX")
    end

    it "checks bank_account IBAN for availability" do
      expect(generator_with_bank_account.available?).to be true
    end

    context "when bank_account has no IBAN" do
      let(:bank_account) { build(:bank_account, iban: nil) }

      it "returns false for available?" do
        # bank_account without IBAN should make it unavailable
        gen = described_class.new(invoice: invoice, settings: settings, bank_account: bank_account)
        expect(gen.available?).to be false
      end
    end
  end
end
