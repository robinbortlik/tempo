require 'rails_helper'

RSpec.describe "Clients", type: :system do
  let(:user) { create(:user) }

  before do
    # Ensure clean state
    Capybara.reset_sessions!

    # Sign in
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    sleep(1) # Wait for any asynchronous processes
    expect(page).to have_current_path(root_path)
  end

  describe "clients index page" do
    it "displays the clients page header" do
      visit clients_path

      expect(page).to have_content("Clients")
      expect(page).to have_content("Manage your client relationships")
      expect(page).to have_button("Add Client")
    end

    it "displays empty state when no clients exist" do
      visit clients_path

      expect(page).to have_content("No clients yet")
    end

    context "with existing clients" do
      let!(:client) { create(:client, name: "Acme Corp", email: "contact@acme.com", currency: "EUR", hourly_rate: 120) }

      it "displays the client in the table" do
        visit clients_path

        expect(page).to have_content("Acme Corp")
        expect(page).to have_content("contact@acme.com")
        expect(page).to have_content("EUR")
      end

      it "navigates to client details when clicking a row" do
        visit clients_path

        # Click on the row containing the client name
        find('td', text: 'Acme Corp').click

        expect(page).to have_current_path(client_path(client))
        expect(page).to have_content("Acme Corp")
      end
    end
  end

  describe "creating a new client" do
    it "navigates to new client page when clicking Add Client" do
      visit clients_path

      click_button "Add Client"

      expect(page).to have_current_path(new_client_path)
      expect(page).to have_content("New Client")
      expect(page).to have_content("Add a new client to your account")
    end

    it "creates a client with valid data" do
      visit new_client_path

      fill_in "Client Name", with: "Test Company"
      fill_in "Email", with: "test@company.com"
      fill_in "Contact Person", with: "John Doe"
      select "EUR - Euro", from: "Currency"
      fill_in "Hourly Rate", with: "150"
      fill_in "Payment Terms", with: "Net 30"

      click_button "Create Client"

      expect(page).to have_content("Client created successfully")
      expect(page).to have_content("Test Company")
    end

    it "disables submit button when name is empty" do
      visit new_client_path

      # Leave name empty - button should be disabled
      fill_in "Email", with: "test@company.com"

      # The Create Client button should be disabled when name is empty
      expect(page).to have_button("Create Client", disabled: true)
    end

    it "validates email format" do
      visit new_client_path

      fill_in "Client Name", with: "Test Company"
      fill_in "Email", with: "invalid-email"
      find("body").click # Trigger blur

      expect(page).to have_content("Please enter a valid email address")
    end

    it "navigates back to clients list when clicking Back" do
      visit new_client_path

      click_on "Back to Clients"

      expect(page).to have_current_path(clients_path)
    end
  end

  describe "viewing a client" do
    let!(:client) do
      create(:client,
        name: "Acme Corporation",
        email: "contact@acme.com",
        contact_person: "John Smith",
        address: "123 Business Ave\nNew York, NY 10001",
        currency: "EUR",
        hourly_rate: 120,
        vat_id: "EU123456789",
        payment_terms: "Net 30"
      )
    end

    it "displays client header with details" do
      visit client_path(client)

      expect(page).to have_content("Acme Corporation")
      expect(page).to have_content("contact@acme.com")
      expect(page).to have_button("Edit")
      expect(page).to have_button("New Invoice")
    end

    it "displays the share link section" do
      visit client_path(client)

      expect(page).to have_content("Client Report Portal")
      expect(page).to have_content(client.share_token)
      expect(page).to have_button("Copy Link")
    end

    it "displays stats cards" do
      visit client_path(client)

      expect(page).to have_content("Total Hours")
      expect(page).to have_content("Total Invoiced")
      expect(page).to have_content("Unbilled Hours")
      expect(page).to have_content("Unbilled Amount")
    end

    it "displays contact details card" do
      visit client_path(client)

      expect(page).to have_content("Contact Details")
      expect(page).to have_content("John Smith")
      expect(page).to have_content("contact@acme.com")
    end

    it "displays billing details card" do
      visit client_path(client)

      expect(page).to have_content("Billing Details")
      expect(page).to have_content("EU123456789")
      expect(page).to have_content("Net 30")
      expect(page).to have_content("EUR")
    end

    it "has working tabs" do
      visit client_path(client)

      within('[role="tablist"]') do
        expect(page).to have_content("Overview")
        expect(page).to have_content("Projects (0)")
        expect(page).to have_content("Settings")
      end

      # Switch to Projects tab
      within('[role="tablist"]') do
        click_on "Projects (0)"
      end
      expect(page).to have_content("No projects yet")

      # Switch to Settings tab
      within('[role="tablist"]') do
        click_on "Settings"
      end
      expect(page).to have_content("Danger Zone")
      expect(page).to have_button("Delete Client")
    end

    it "navigates back to clients list" do
      visit client_path(client)

      click_on "Back to Clients"

      expect(page).to have_current_path(clients_path)
    end

    context "with projects" do
      let!(:project) { create(:project, client: client, name: "API Integration", hourly_rate: 150, active: true) }

      it "displays projects in the Projects tab" do
        visit client_path(client)

        click_on "Projects (1)"

        expect(page).to have_content("API Integration")
      end
    end
  end

  describe "editing a client" do
    let!(:client) { create(:client, name: "Original Name", email: "original@email.com") }

    it "displays the edit form with existing data" do
      visit edit_client_path(client)

      expect(page).to have_content("Edit Client")
      expect(page).to have_field("Client Name", with: "Original Name")
      expect(page).to have_field("Email", with: "original@email.com")
    end

    it "updates the client with valid data" do
      visit edit_client_path(client)

      fill_in "Client Name", with: "Updated Name", fill_options: { clear: :backspace }
      fill_in "Email", with: "updated@email.com", fill_options: { clear: :backspace }

      click_button "Save Changes"

      expect(page).to have_content("Client updated successfully")
      expect(page).to have_content("Updated Name")
    end

    it "navigates back to client details when clicking Back" do
      visit edit_client_path(client)

      click_on "Back to Original Name"

      expect(page).to have_current_path(client_path(client))
    end

    it "can cancel editing" do
      visit edit_client_path(client)

      click_button "Cancel"

      expect(page).to have_current_path(client_path(client))
    end
  end

  describe "deleting a client" do
    let!(:client) { create(:client, name: "Client To Delete") }

    it "shows delete confirmation dialog" do
      visit client_path(client)

      within('[role="tablist"]') do
        click_on "Settings"
      end
      click_button "Delete Client"

      expect(page).to have_content("Delete Client To Delete?")
      expect(page).to have_content("This action cannot be undone")
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Delete")
    end

    it "deletes the client when confirmed" do
      visit client_path(client)

      within('[role="tablist"]') do
        click_on "Settings"
      end
      click_button "Delete Client"

      within('[role="alertdialog"]') do
        click_button "Delete"
      end

      expect(page).to have_current_path(clients_path)
      expect(page).to have_content("Client deleted successfully")
      expect(page).not_to have_content("Client To Delete")
    end

    it "can cancel deletion" do
      visit client_path(client)

      within('[role="tablist"]') do
        click_on "Settings"
      end
      click_button "Delete Client"

      within('[role="alertdialog"]') do
        click_button "Cancel"
      end

      expect(page).to have_current_path(client_path(client))
      expect(page).to have_content("Client To Delete")
    end

    context "with associated projects" do
      before do
        create(:project, client: client)
      end

      it "shows error when trying to delete client with projects" do
        visit client_path(client)

        within('[role="tablist"]') do
          click_on "Settings"
        end
        click_button "Delete Client"

        within('[role="alertdialog"]') do
          click_button "Delete"
        end

        expect(page).to have_content("Cannot delete client with associated projects or invoices")
      end
    end
  end

  describe "page styling" do
    let!(:client) { create(:client) }

    it "uses the correct styling on index page" do
      visit clients_path

      expect(page).to have_css(".bg-white.rounded-xl.border")
    end

    it "uses the correct styling on show page" do
      visit client_path(client)

      # Stats cards
      expect(page).to have_css(".bg-white.rounded-xl.border")
      expect(page).to have_css(".bg-amber-50.border-amber-200")

      # Share link section
      expect(page).to have_css(".bg-amber-50.border.border-amber-200")
    end

    it "uses the correct styling on form pages" do
      visit new_client_path

      expect(page).to have_css(".bg-white.rounded-xl.border")
      expect(page).to have_css(".bg-stone-50")
    end
  end
end
