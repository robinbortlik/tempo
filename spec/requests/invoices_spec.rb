require 'rails_helper'

RSpec.describe InvoicesController, type: :request do
  let(:client) { create(:client, hourly_rate: 100, currency: "EUR") }
  let(:project) { create(:project, client: client, hourly_rate: 100) }

  describe "GET /invoices" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get invoices_path
        expect(response).to have_http_status(:success)
      end

      it "renders the Invoices/Index Inertia component" do
        get invoices_path
        expect(response.body).to include('Invoices/Index')
      end

      it "returns an empty list when no invoices exist" do
        get invoices_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        expect(json_response['props']['invoices']).to eq([])
      end

      it "returns all invoices with client info" do
        invoice = create(:invoice, client: client, status: :draft, total_hours: 10, total_amount: 1000)

        get invoices_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        invoices = json_response['props']['invoices']

        expect(invoices.length).to eq(1)
        expect(invoices.first['number']).to eq(invoice.number)
        expect(invoices.first['status']).to eq("draft")
        expect(invoices.first['client_name']).to eq(client.name)
      end

      context "with filters" do
        before do
          @draft_invoice = create(:invoice, client: client, status: :draft)
          @final_invoice = create(:invoice, client: client, status: :final)
        end

        it "filters by status" do
          get invoices_path(status: "draft"), headers: inertia_headers

          json_response = JSON.parse(response.body)
          invoices = json_response['props']['invoices']

          expect(invoices.length).to eq(1)
          expect(invoices.first['status']).to eq("draft")
        end

        it "filters by client" do
          other_client = create(:client)
          create(:invoice, client: other_client)

          get invoices_path(client_id: client.id), headers: inertia_headers

          json_response = JSON.parse(response.body)
          invoices = json_response['props']['invoices']

          expect(invoices.length).to eq(2)
          expect(invoices.map { |i| i['client_id'] }).to all(eq(client.id))
        end

        it "filters by year" do
          get invoices_path(year: Date.current.year), headers: inertia_headers

          json_response = JSON.parse(response.body)
          invoices = json_response['props']['invoices']

          expect(invoices.length).to eq(2)
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get invoices_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /invoices/:id" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        invoice = create(:invoice, client: client)
        get invoice_path(invoice)
        expect(response).to have_http_status(:success)
      end

      it "renders the Invoices/Show Inertia component" do
        invoice = create(:invoice, client: client)
        get invoice_path(invoice)
        expect(response.body).to include('Invoices/Show')
      end

      it "returns invoice with all details" do
        invoice = create(:invoice, client: client, notes: "Thank you!")

        get invoice_path(invoice), headers: inertia_headers

        json_response = JSON.parse(response.body)
        invoice_data = json_response['props']['invoice']

        expect(invoice_data['id']).to eq(invoice.id)
        expect(invoice_data['number']).to eq(invoice.number)
        expect(invoice_data['status']).to eq(invoice.status)
        expect(invoice_data['notes']).to eq("Thank you!")
        expect(invoice_data['client_name']).to eq(client.name)
      end

      it "returns associated time entries" do
        invoice = create(:invoice, client: client)
        entry = create(:time_entry, project: project, invoice: invoice, status: :invoiced)

        get invoice_path(invoice), headers: inertia_headers

        json_response = JSON.parse(response.body)
        entries = json_response['props']['time_entries']

        expect(entries.length).to eq(1)
        expect(entries.first['id']).to eq(entry.id)
      end

      it "returns project groups" do
        invoice = create(:invoice, client: client)
        create(:time_entry, project: project, invoice: invoice, hours: 8, status: :invoiced)

        get invoice_path(invoice), headers: inertia_headers

        json_response = JSON.parse(response.body)
        groups = json_response['props']['project_groups']

        expect(groups.length).to eq(1)
        expect(groups.first['project']['name']).to eq(project.name)
        expect(groups.first['total_hours'].to_f).to eq(8)
      end

      it "returns 404 for non-existent invoice" do
        get invoice_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        invoice = create(:invoice, client: client)
        get invoice_path(invoice)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /invoices/new" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get new_invoice_path
        expect(response).to have_http_status(:success)
      end

      it "renders the Invoices/New Inertia component" do
        get new_invoice_path
        expect(response.body).to include('Invoices/New')
      end

      it "returns clients for selection" do
        client

        get new_invoice_path, headers: inertia_headers

        json_response = JSON.parse(response.body)
        clients = json_response['props']['clients']

        expect(clients.length).to eq(1)
        expect(clients.first['name']).to eq(client.name)
      end

      it "returns preview data when client and dates provided" do
        create(:time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)

        get new_invoice_path(
          client_id: client.id,
          period_start: "2024-12-01",
          period_end: "2024-12-31"
        ), headers: inertia_headers

        json_response = JSON.parse(response.body)
        preview = json_response['props']['preview']

        expect(preview).not_to be_nil
        expect(preview['total_hours'].to_f).to eq(8)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_invoice_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /invoices/:id/edit" do
    context "when authenticated" do
      before { sign_in }

      context "when invoice is draft" do
        it "returns a successful response" do
          invoice = create(:invoice, client: client, status: :draft)
          get edit_invoice_path(invoice)
          expect(response).to have_http_status(:success)
        end

        it "renders the Invoices/Edit Inertia component" do
          invoice = create(:invoice, client: client, status: :draft)
          get edit_invoice_path(invoice)
          expect(response.body).to include('Invoices/Edit')
        end
      end

      context "when invoice is final" do
        it "redirects to show with error" do
          invoice = create(:invoice, client: client, status: :final)
          get edit_invoice_path(invoice)
          expect(response).to redirect_to(invoice_path(invoice))
          follow_redirect!
          expect(flash[:alert]).to eq("Cannot edit a finalized invoice.")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        invoice = create(:invoice, client: client)
        get edit_invoice_path(invoice)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /invoices" do
    context "when authenticated" do
      before { sign_in }

      context "with valid params and unbilled entries" do
        before do
          create(:time_entry, project: project, date: Date.new(2024, 12, 15), hours: 8, status: :unbilled)
        end

        it "creates a new invoice" do
          expect {
            post invoices_path, params: {
              invoice: {
                client_id: client.id,
                period_start: "2024-12-01",
                period_end: "2024-12-31",
                issue_date: "2024-12-29",
                due_date: "2025-01-28"
              }
            }
          }.to change(Invoice, :count).by(1)
        end

        it "redirects to the invoice show page with success notice" do
          post invoices_path, params: {
            invoice: {
              client_id: client.id,
              period_start: "2024-12-01",
              period_end: "2024-12-31"
            }
          }

          invoice = Invoice.last
          expect(response).to redirect_to(invoice_path(invoice))
          follow_redirect!
          expect(flash[:notice]).to eq("Invoice created successfully.")
        end

        it "associates time entries with the invoice" do
          entry = TimeEntry.first

          post invoices_path, params: {
            invoice: {
              client_id: client.id,
              period_start: "2024-12-01",
              period_end: "2024-12-31"
            }
          }

          invoice = Invoice.last
          expect(entry.reload.invoice_id).to eq(invoice.id)
        end

        it "creates invoice with notes" do
          post invoices_path, params: {
            invoice: {
              client_id: client.id,
              period_start: "2024-12-01",
              period_end: "2024-12-31",
              notes: "Thank you for your business!"
            }
          }

          invoice = Invoice.last
          expect(invoice.notes).to eq("Thank you for your business!")
        end
      end

      context "without unbilled entries" do
        it "does not create an invoice" do
          expect {
            post invoices_path, params: {
              invoice: {
                client_id: client.id,
                period_start: "2024-12-01",
                period_end: "2024-12-31"
              }
            }
          }.not_to change(Invoice, :count)
        end

        it "redirects to new with error message" do
          post invoices_path, params: {
            invoice: {
              client_id: client.id,
              period_start: "2024-12-01",
              period_end: "2024-12-31"
            }
          }

          expect(response).to redirect_to(new_invoice_path(client_id: client.id.to_s, period_start: "2024-12-01", period_end: "2024-12-31"))
          follow_redirect!
          expect(flash[:alert]).to include("No unbilled time entries")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post invoices_path, params: {
          invoice: { client_id: client.id, period_start: "2024-12-01", period_end: "2024-12-31" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /invoices/:id" do
    context "when authenticated" do
      before { sign_in }

      context "when invoice is draft" do
        it "updates the invoice" do
          invoice = create(:invoice, client: client, status: :draft, notes: nil)

          patch invoice_path(invoice), params: {
            invoice: { notes: "Updated notes" }
          }

          expect(invoice.reload.notes).to eq("Updated notes")
        end

        it "redirects to invoice show with success notice" do
          invoice = create(:invoice, client: client, status: :draft)

          patch invoice_path(invoice), params: {
            invoice: { notes: "Updated" }
          }

          expect(response).to redirect_to(invoice_path(invoice))
          follow_redirect!
          expect(flash[:notice]).to eq("Invoice updated successfully.")
        end

        it "updates issue_date and due_date" do
          invoice = create(:invoice, client: client, status: :draft)

          patch invoice_path(invoice), params: {
            invoice: {
              issue_date: "2024-12-30",
              due_date: "2025-01-30"
            }
          }

          invoice.reload
          expect(invoice.issue_date).to eq(Date.new(2024, 12, 30))
          expect(invoice.due_date).to eq(Date.new(2025, 1, 30))
        end
      end

      context "when invoice is final" do
        it "does not update the invoice" do
          invoice = create(:invoice, client: client, status: :final, notes: "Original")

          patch invoice_path(invoice), params: {
            invoice: { notes: "Updated" }
          }

          expect(invoice.reload.notes).to eq("Original")
        end

        it "redirects with error message" do
          invoice = create(:invoice, client: client, status: :final)

          patch invoice_path(invoice), params: {
            invoice: { notes: "Updated" }
          }

          expect(response).to redirect_to(invoice_path(invoice))
          follow_redirect!
          expect(flash[:alert]).to eq("Cannot update a finalized invoice.")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        invoice = create(:invoice, client: client)
        patch invoice_path(invoice), params: {
          invoice: { notes: "Test" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /invoices/:id" do
    context "when authenticated" do
      before { sign_in }

      context "when invoice is draft" do
        it "deletes the invoice" do
          invoice = create(:invoice, client: client, status: :draft)

          expect {
            delete invoice_path(invoice)
          }.to change(Invoice, :count).by(-1)
        end

        it "redirects to invoices index with success notice" do
          invoice = create(:invoice, client: client, status: :draft)

          delete invoice_path(invoice)

          expect(response).to redirect_to(invoices_path)
          follow_redirect!
          expect(flash[:notice]).to eq("Invoice deleted successfully.")
        end

        it "unassociates time entries and marks them as unbilled" do
          invoice = create(:invoice, client: client, status: :draft)
          entry = create(:time_entry, project: project, invoice: invoice, status: :unbilled)

          delete invoice_path(invoice)

          entry.reload
          expect(entry.invoice_id).to be_nil
          expect(entry.status).to eq("unbilled")
        end
      end

      context "when invoice is final" do
        it "does not delete the invoice" do
          invoice = create(:invoice, client: client, status: :final)

          expect {
            delete invoice_path(invoice)
          }.not_to change(Invoice, :count)
        end

        it "redirects with error message" do
          invoice = create(:invoice, client: client, status: :final)

          delete invoice_path(invoice)

          expect(response).to redirect_to(invoice_path(invoice))
          follow_redirect!
          expect(flash[:alert]).to eq("Cannot delete a finalized invoice.")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        invoice = create(:invoice, client: client)
        delete invoice_path(invoice)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /invoices/:id/finalize" do
    context "when authenticated" do
      before { sign_in }

      context "when invoice is draft" do
        it "marks invoice as final" do
          invoice = create(:invoice, client: client, status: :draft)

          post finalize_invoice_path(invoice)

          expect(invoice.reload.status).to eq("final")
        end

        it "marks all associated time entries as invoiced" do
          invoice = create(:invoice, client: client, status: :draft)
          entry = create(:time_entry, project: project, invoice: invoice, status: :unbilled)

          post finalize_invoice_path(invoice)

          expect(entry.reload.status).to eq("invoiced")
        end

        it "redirects to invoice show with success notice" do
          invoice = create(:invoice, client: client, status: :draft)

          post finalize_invoice_path(invoice)

          expect(response).to redirect_to(invoice_path(invoice))
          follow_redirect!
          expect(flash[:notice]).to eq("Invoice finalized successfully.")
        end
      end

      context "when invoice is already final" do
        it "does not change invoice status" do
          invoice = create(:invoice, client: client, status: :final)

          post finalize_invoice_path(invoice)

          expect(invoice.reload.status).to eq("final")
        end

        it "redirects with error message" do
          invoice = create(:invoice, client: client, status: :final)

          post finalize_invoice_path(invoice)

          expect(response).to redirect_to(invoice_path(invoice))
          follow_redirect!
          expect(flash[:alert]).to eq("Invoice is already finalized.")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        invoice = create(:invoice, client: client)
        post finalize_invoice_path(invoice)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  private

  def inertia_headers
    {
      'X-Inertia' => 'true',
      'X-Inertia-Version' => ViteRuby.digest
    }
  end
end
