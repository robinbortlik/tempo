require 'rails_helper'

RSpec.describe "Bank Account Invoice Workflow", type: :request do
  before { sign_in }

  let(:default_bank_account) do
    create(:bank_account, :default,
      name: "Default EUR Account",
      iban: "DE89370400440532013000",
      bank_swift: "COBADEFFXXX"
    )
  end

  let(:alternate_bank_account) do
    create(:bank_account,
      name: "Alternate CZK Account",
      iban: "CZ6508000000192000145399",
      bank_swift: "GIBACZPX"
    )
  end

  describe "Invoice creation captures correct bank account" do
    context "when client has a bank account assigned" do
      it "captures client's bank account on invoice creation" do
        client = create(:client, hourly_rate: 100, currency: "EUR", bank_account: alternate_bank_account)
        project = create(:project, client: client, hourly_rate: 100)
        create(:work_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)

        # Ensure default exists
        default_bank_account

        post invoices_path, params: {
          invoice: {
            client_id: client.id,
            period_start: "2024-12-01",
            period_end: "2024-12-31"
          }
        }

        invoice = Invoice.last
        expect(invoice.bank_account_id).to eq(alternate_bank_account.id)
      end
    end

    context "when client has no bank account assigned" do
      it "captures default bank account on invoice creation" do
        client = create(:client, hourly_rate: 100, currency: "EUR", bank_account: nil)
        project = create(:project, client: client, hourly_rate: 100)
        create(:work_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)

        # Ensure default exists
        default_bank_account

        post invoices_path, params: {
          invoice: {
            client_id: client.id,
            period_start: "2024-12-01",
            period_end: "2024-12-31"
          }
        }

        invoice = Invoice.last
        expect(invoice.bank_account_id).to eq(default_bank_account.id)
      end
    end
  end

  describe "Invoice bank account persists through lifecycle" do
    it "changing client's bank account does not affect existing invoices" do
      original_bank_account = alternate_bank_account
      new_bank_account = create(:bank_account, name: "New Account", iban: "FR7630006000011234567890189")

      client = create(:client, hourly_rate: 100, currency: "EUR", bank_account: original_bank_account)
      project = create(:project, client: client, hourly_rate: 100)
      create(:work_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)

      # Ensure default exists
      default_bank_account

      # Create invoice - captures original bank account
      post invoices_path, params: {
        invoice: {
          client_id: client.id,
          period_start: "2024-12-01",
          period_end: "2024-12-31"
        }
      }

      invoice = Invoice.last
      expect(invoice.bank_account_id).to eq(original_bank_account.id)

      # Change client's bank account
      client.update!(bank_account: new_bank_account)

      # Verify existing invoice still has original bank account
      expect(invoice.reload.bank_account_id).to eq(original_bank_account.id)
      expect(invoice.bank_account).to eq(original_bank_account)
    end

    it "finalizing invoice preserves bank account reference" do
      client = create(:client, hourly_rate: 100, currency: "EUR", bank_account: alternate_bank_account)
      project = create(:project, client: client, hourly_rate: 100)
      create(:work_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)

      # Ensure default exists
      default_bank_account

      # Create invoice
      post invoices_path, params: {
        invoice: {
          client_id: client.id,
          period_start: "2024-12-01",
          period_end: "2024-12-31"
        }
      }

      invoice = Invoice.last

      # Finalize invoice
      post finalize_invoice_path(invoice)

      # Verify bank account reference persists
      expect(invoice.reload.status).to eq("final")
      expect(invoice.bank_account_id).to eq(alternate_bank_account.id)
    end
  end
end
