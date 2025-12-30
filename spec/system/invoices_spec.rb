require 'rails_helper'

RSpec.describe "Invoices", type: :system do
  let(:user) { create(:user) }
  let!(:client) { create(:client, name: "Acme Corporation", currency: "EUR", hourly_rate: 120) }
  let!(:project) { create(:project, client: client, name: "API Integration", hourly_rate: 150) }

  before do
    # Ensure clean state
    Capybara.reset_sessions!

    # Sign in
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    expect(page).to have_current_path(root_path)
  end

  describe "invoices index page" do
    it "displays the invoices page header" do
      visit invoices_path

      expect(page).to have_content("Invoices")
      expect(page).to have_content("Manage your invoices")
      expect(page).to have_button("New Invoice")
    end

    it "displays empty state when no invoices exist" do
      visit invoices_path

      expect(page).to have_content("No invoices yet")
    end

    it "displays filter tabs" do
      visit invoices_path

      expect(page).to have_css('[role="tab"]', text: "All")
      expect(page).to have_css('[role="tab"]', text: /Draft/)
      expect(page).to have_css('[role="tab"]', text: /Final/)
    end

    context "with existing invoices" do
      let!(:draft_invoice) do
        create(:invoice,
          client: client,
          number: "2024-001",
          status: :draft,
          period_start: Date.new(2024, 12, 1),
          period_end: Date.new(2024, 12, 15),
          total_hours: 24,
          total_amount: 2880,
          currency: "EUR"
        )
      end

      let!(:final_invoice) do
        create(:invoice,
          client: client,
          number: "2024-002",
          status: :final,
          period_start: Date.new(2024, 11, 1),
          period_end: Date.new(2024, 11, 30),
          total_hours: 40,
          total_amount: 4800,
          currency: "EUR"
        )
      end

      it "displays invoices in the table" do
        visit invoices_path

        expect(page).to have_content("2024-001")
        expect(page).to have_content("2024-002")
        expect(page).to have_content("Acme Corporation")
      end

      it "displays status badges correctly" do
        visit invoices_path

        expect(page).to have_content("Draft")
        expect(page).to have_content("Final")
      end

      it "navigates to invoice details when clicking a row" do
        visit invoices_path

        find('td', text: '2024-001').click

        expect(page).to have_current_path(invoice_path(draft_invoice))
        expect(page).to have_content("2024-001")
      end

      it "filters invoices by draft status" do
        visit invoices_path

        find('[role="tab"]', text: /Draft/).click

        expect(page).to have_content("2024-001")
        expect(page).not_to have_content("2024-002")
      end

      it "filters invoices by final status" do
        visit invoices_path

        find('[role="tab"]', text: /Final/).click

        expect(page).to have_content("2024-002")
        expect(page).not_to have_content("2024-001")
      end
    end
  end

  describe "creating a new invoice" do
    let!(:time_entry1) do
      create(:time_entry,
        project: project,
        date: Date.current,
        hours: 8,
        description: "API development",
        status: :unbilled
      )
    end

    let!(:time_entry2) do
      create(:time_entry,
        project: project,
        date: Date.current - 1.day,
        hours: 4,
        description: "Code review",
        status: :unbilled
      )
    end

    it "navigates to new invoice page when clicking New Invoice" do
      visit invoices_path

      click_button "New Invoice"

      expect(page).to have_current_path(new_invoice_path)
      expect(page).to have_content("New Invoice")
      expect(page).to have_content("Create a new invoice from unbilled time entries")
    end

    it "displays client selector" do
      visit new_invoice_path

      expect(page).to have_select("client_id")
      expect(page).to have_content("Acme Corporation")
    end

    it "displays date selectors" do
      visit new_invoice_path

      expect(page).to have_field("period_start")
      expect(page).to have_field("period_end")
      expect(page).to have_field("issue_date")
      expect(page).to have_field("due_date")
    end

    it "shows preview when client and dates are selected" do
      # Set up period to include the time entries
      visit new_invoice_path(
        client_id: client.id,
        period_start: (Date.current - 7.days).to_s,
        period_end: Date.current.to_s
      )

      expect(page).to have_content("Preview")
      expect(page).to have_content("API Integration")
      expect(page).to have_content("API development")
    end

    it "creates a draft invoice" do
      visit new_invoice_path(
        client_id: client.id,
        period_start: (Date.current - 7.days).to_s,
        period_end: Date.current.to_s
      )

      click_button "Create Draft"

      expect(page).to have_content("Invoice created successfully")
      expect(page).to have_content("Draft")
    end

    it "navigates back to invoices list when clicking Back" do
      visit new_invoice_path

      click_on "Back to Invoices"

      expect(page).to have_current_path(invoices_path)
    end
  end

  describe "viewing an invoice" do
    let!(:invoice) do
      create(:invoice,
        client: client,
        number: "2024-001",
        status: :draft,
        issue_date: Date.new(2024, 12, 29),
        due_date: Date.new(2025, 1, 28),
        period_start: Date.new(2024, 12, 16),
        period_end: Date.new(2024, 12, 31),
        total_hours: 24,
        total_amount: 2880,
        currency: "EUR",
        notes: "Thank you for your business"
      )
    end

    let!(:time_entry) do
      create(:time_entry,
        project: project,
        invoice: invoice,
        date: Date.new(2024, 12, 20),
        hours: 8,
        description: "API development",
        status: :invoiced
      )
    end

    it "displays invoice header with number and status" do
      visit invoice_path(invoice)

      expect(page).to have_content("2024-001")
      expect(page).to have_content("Draft")
      expect(page).to have_content("Acme Corporation")
    end

    it "displays action buttons for draft invoice" do
      visit invoice_path(invoice)

      expect(page).to have_link("Download PDF")
      expect(page).to have_button("Edit")
      expect(page).to have_button("Mark as Final")
      expect(page).to have_button("Delete")
    end

    it "displays invoice details" do
      visit invoice_path(invoice)

      expect(page).to have_content("INVOICE")
      expect(page).to have_content("#2024-001")
      expect(page).to have_content("Issue Date")
      expect(page).to have_content("Due Date")
    end

    it "displays client information" do
      visit invoice_path(invoice)

      expect(page).to have_content("Bill To:")
      expect(page).to have_content("Acme Corporation")
    end

    it "displays time entries" do
      visit invoice_path(invoice)

      expect(page).to have_content("API development")
      expect(page).to have_content("API Integration")
    end

    it "displays totals" do
      visit invoice_path(invoice)

      expect(page).to have_content("Subtotal")
      expect(page).to have_content("Total Due")
    end

    it "displays notes when present" do
      visit invoice_path(invoice)

      expect(page).to have_content("Notes")
      expect(page).to have_content("Thank you for your business")
    end

    it "navigates back to invoices list" do
      visit invoice_path(invoice)

      click_on "Back to Invoices"

      expect(page).to have_current_path(invoices_path)
    end

    context "when invoice is final" do
      before do
        invoice.update!(status: :final)
      end

      it "does not display edit, finalize, or delete buttons" do
        visit invoice_path(invoice)

        expect(page).to have_link("Download PDF")
        expect(page).not_to have_button("Edit")
        expect(page).not_to have_button("Mark as Final")
        expect(page).not_to have_button("Delete")
      end
    end
  end

  describe "editing an invoice" do
    let!(:invoice) do
      create(:invoice,
        client: client,
        number: "2024-001",
        status: :draft,
        issue_date: Date.new(2024, 12, 29),
        due_date: Date.new(2025, 1, 28),
        period_start: Date.new(2024, 12, 16),
        period_end: Date.new(2024, 12, 31),
        total_hours: 24,
        total_amount: 2880,
        currency: "EUR"
      )
    end

    let!(:time_entry) do
      create(:time_entry,
        project: project,
        invoice: invoice,
        date: Date.new(2024, 12, 20),
        hours: 8,
        description: "API development"
      )
    end

    it "displays the edit form with existing data" do
      visit edit_invoice_path(invoice)

      expect(page).to have_content("Edit Invoice 2024-001")
      expect(page).to have_content("Acme Corporation")
      expect(page).to have_field("issue_date", with: "2024-12-29")
      expect(page).to have_field("due_date", with: "2025-01-28")
    end

    it "updates the invoice with valid data" do
      visit edit_invoice_path(invoice)

      fill_in "due_date", with: "2025-02-15"
      fill_in "notes", with: "Updated notes"

      click_button "Save Changes"

      expect(page).to have_content("Invoice updated successfully")
      expect(page).to have_content("Notes")
      expect(page).to have_content("Updated notes")
    end

    it "displays invoice entries preview" do
      visit edit_invoice_path(invoice)

      expect(page).to have_content("Invoice Entries")
      expect(page).to have_content("API Integration")
      expect(page).to have_content("API development")
    end

    it "can cancel editing" do
      visit edit_invoice_path(invoice)

      click_button "Cancel"

      expect(page).to have_current_path(invoice_path(invoice))
    end

    it "navigates back to invoice details when clicking Back" do
      visit edit_invoice_path(invoice)

      click_on "Back to Invoice 2024-001"

      expect(page).to have_current_path(invoice_path(invoice))
    end
  end

  describe "finalizing an invoice" do
    let!(:invoice) do
      create(:invoice,
        client: client,
        number: "2024-001",
        status: :draft,
        total_hours: 24,
        total_amount: 2880,
        currency: "EUR"
      )
    end

    let!(:time_entry) do
      create(:time_entry,
        project: project,
        invoice: invoice,
        hours: 8,
        status: :unbilled
      )
    end

    it "shows finalize confirmation dialog" do
      visit invoice_path(invoice)

      click_button "Mark as Final"

      expect(page).to have_content("Finalize Invoice?")
      expect(page).to have_content("This will mark the invoice as final")
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Finalize")
    end

    it "finalizes the invoice when confirmed" do
      visit invoice_path(invoice)

      click_button "Mark as Final"

      within('[role="alertdialog"]') do
        click_button "Finalize"
      end

      expect(page).to have_content("Invoice finalized successfully")
      expect(page).to have_content("Final")
      expect(page).not_to have_button("Edit")
      expect(page).not_to have_button("Mark as Final")
    end

    it "can cancel finalization" do
      visit invoice_path(invoice)

      click_button "Mark as Final"

      within('[role="alertdialog"]') do
        click_button "Cancel"
      end

      expect(page).to have_content("Draft")
      expect(page).to have_button("Mark as Final")
    end
  end

  describe "deleting an invoice" do
    let!(:invoice) do
      create(:invoice,
        client: client,
        number: "2024-001",
        status: :draft,
        total_hours: 24,
        total_amount: 2880,
        currency: "EUR"
      )
    end

    let!(:time_entry) do
      create(:time_entry,
        project: project,
        invoice: invoice,
        hours: 8,
        status: :unbilled
      )
    end

    it "shows delete confirmation dialog" do
      visit invoice_path(invoice)

      click_button "Delete"

      expect(page).to have_content("Delete Invoice 2024-001?")
      expect(page).to have_content("This will permanently delete the invoice")
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Delete")
    end

    it "deletes the invoice when confirmed" do
      visit invoice_path(invoice)

      click_button "Delete"

      within('[role="alertdialog"]') do
        click_button "Delete"
      end

      expect(page).to have_current_path(invoices_path)
      expect(page).to have_content("Invoice deleted successfully")
      expect(page).not_to have_content("2024-001")
    end

    it "can cancel deletion" do
      visit invoice_path(invoice)

      click_button "Delete"

      within('[role="alertdialog"]') do
        click_button "Cancel"
      end

      expect(page).to have_current_path(invoice_path(invoice))
      expect(page).to have_content("2024-001")
    end
  end

  describe "page styling" do
    let!(:invoice) { create(:invoice, client: client, status: :draft) }

    it "uses the correct styling on index page" do
      visit invoices_path

      expect(page).to have_css(".bg-white.rounded-xl.border")
    end

    it "uses the correct styling on show page" do
      visit invoice_path(invoice)

      expect(page).to have_css(".bg-white.rounded-xl.border")
    end

    it "uses the correct styling on form pages" do
      visit new_invoice_path

      expect(page).to have_css(".bg-white.rounded-xl.border")
      expect(page).to have_css(".bg-stone-50")
    end

    it "displays draft badge with amber styling" do
      visit invoices_path

      expect(page).to have_css(".bg-amber-100.text-amber-700", text: "Draft")
    end

    it "displays final badge with emerald styling" do
      invoice.update!(status: :final)
      visit invoices_path

      expect(page).to have_css(".bg-emerald-100.text-emerald-700", text: "Final")
    end
  end
end
