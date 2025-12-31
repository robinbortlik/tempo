require 'rails_helper'

RSpec.describe Client, type: :model do
  describe "validations" do
    subject { build(:client) }

    it { is_expected.to be_valid }

    describe "name" do
      it "requires name to be present" do
        client = build(:client, name: nil)
        expect(client).not_to be_valid
        expect(client.errors[:name]).to include("can't be blank")
      end

      it "requires name to not be empty string" do
        client = build(:client, name: "")
        expect(client).not_to be_valid
        expect(client.errors[:name]).to include("can't be blank")
      end
    end

    describe "hourly_rate" do
      it "allows nil hourly_rate" do
        client = build(:client, hourly_rate: nil)
        expect(client).to be_valid
      end

      it "allows positive hourly_rate" do
        client = build(:client, hourly_rate: 100.00)
        expect(client).to be_valid
      end

      it "rejects zero hourly_rate" do
        client = build(:client, hourly_rate: 0)
        expect(client).not_to be_valid
        expect(client.errors[:hourly_rate]).to include("must be greater than 0")
      end

      it "rejects negative hourly_rate" do
        client = build(:client, hourly_rate: -50)
        expect(client).not_to be_valid
        expect(client.errors[:hourly_rate]).to include("must be greater than 0")
      end

      it "allows decimal hourly_rate" do
        client = build(:client, hourly_rate: 125.50)
        expect(client).to be_valid
      end
    end

    describe "currency" do
      it "allows blank currency" do
        client = build(:client, currency: nil)
        expect(client).to be_valid
      end

      it "allows valid 3-letter uppercase currency code" do
        %w[EUR USD GBP CHF JPY].each do |currency|
          client = build(:client, currency: currency)
          expect(client).to be_valid, "Expected #{currency} to be valid"
        end
      end

      it "rejects lowercase currency codes" do
        client = build(:client, currency: "eur")
        expect(client).not_to be_valid
        expect(client.errors[:currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
      end

      it "rejects mixed case currency codes" do
        client = build(:client, currency: "Eur")
        expect(client).not_to be_valid
        expect(client.errors[:currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
      end

      it "rejects currency codes with wrong length" do
        client = build(:client, currency: "EU")
        expect(client).not_to be_valid
        expect(client.errors[:currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")

        client = build(:client, currency: "EURO")
        expect(client).not_to be_valid
        expect(client.errors[:currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
      end

      it "rejects currency codes with numbers" do
        client = build(:client, currency: "EU1")
        expect(client).not_to be_valid
        expect(client.errors[:currency]).to include("must be 3 uppercase letters (e.g., EUR, USD, GBP)")
      end
    end

    describe "email" do
      it "allows blank email" do
        client = build(:client, email: nil)
        expect(client).to be_valid
      end

      it "allows valid email format" do
        client = build(:client, email: "valid@example.com")
        expect(client).to be_valid
      end

      it "rejects invalid email format" do
        client = build(:client, email: "invalid-email")
        expect(client).not_to be_valid
        expect(client.errors[:email]).to include("must be a valid email address")
      end

      it "rejects email without domain" do
        client = build(:client, email: "user@")
        expect(client).not_to be_valid
        expect(client.errors[:email]).to include("must be a valid email address")
      end
    end

    describe "share_token" do
      it "requires share_token to be unique" do
        existing_client = create(:client)
        new_client = build(:client)
        new_client.share_token = existing_client.share_token
        expect(new_client).not_to be_valid
        expect(new_client.errors[:share_token]).to include("has already been taken")
      end
    end

    describe "default_vat_rate" do
      it "accepts and persists default_vat_rate decimal value" do
        client = create(:client, default_vat_rate: 21.00)
        expect(client.reload.default_vat_rate).to eq(21.00)
      end

      it "allows nil default_vat_rate" do
        client = create(:client, default_vat_rate: nil)
        expect(client).to be_valid
        expect(client.default_vat_rate).to be_nil
      end
    end
  end

  describe "share_token generation" do
    it "auto-generates share_token on create" do
      client = build(:client)
      client.share_token = nil
      expect(client.share_token).to be_nil
      client.valid?
      expect(client.share_token).to be_present
    end

    it "generates a UUID format token" do
      client = create(:client)
      uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
      expect(client.share_token).to match(uuid_regex)
    end

    it "does not overwrite existing share_token" do
      custom_token = "custom-token-12345"
      client = build(:client, share_token: custom_token)
      client.valid?
      expect(client.share_token).to eq(custom_token)
    end

    it "generates unique tokens for different clients" do
      client1 = create(:client)
      client2 = create(:client)
      expect(client1.share_token).not_to eq(client2.share_token)
    end
  end

  describe "attributes" do
    subject { build(:client) }

    it "stores address as text" do
      subject.address = "123 Main St\nCity, State 12345"
      expect(subject.address).to eq("123 Main St\nCity, State 12345")
    end

    it "stores contact_person" do
      subject.contact_person = "Jane Smith"
      expect(subject.contact_person).to eq("Jane Smith")
    end

    it "stores vat_id" do
      subject.vat_id = "VAT123456789"
      expect(subject.vat_id).to eq("VAT123456789")
    end

    it "stores company_registration" do
      subject.company_registration = "REG-98765"
      expect(subject.company_registration).to eq("REG-98765")
    end

    it "stores bank_details as text" do
      bank_info = "Bank: Example Bank\nIBAN: DE89370400440532013000"
      subject.bank_details = bank_info
      expect(subject.bank_details).to eq(bank_info)
    end

    it "stores payment_terms as text" do
      subject.payment_terms = "Net 30 days from invoice date"
      expect(subject.payment_terms).to eq("Net 30 days from invoice date")
    end
  end

  describe "factory" do
    it "creates a valid client" do
      client = build(:client)
      expect(client).to be_valid
    end

    it "creates a client with auto-generated share_token" do
      client = create(:client)
      expect(client.share_token).to be_present
    end

    it "creates a minimal client" do
      client = build(:client, :minimal)
      expect(client).to be_valid
    end

    it "creates a USD client" do
      client = build(:client, :usd)
      expect(client.currency).to eq("USD")
    end

    it "creates a GBP client" do
      client = build(:client, :gbp)
      expect(client.currency).to eq("GBP")
    end

    it "creates a client with custom rate" do
      client = build(:client, :with_custom_rate, rate: 200.00)
      expect(client.hourly_rate).to eq(200.00)
    end

    it "generates unique names with sequence" do
      client1 = create(:client)
      client2 = create(:client)
      expect(client1.name).not_to eq(client2.name)
    end
  end
end
