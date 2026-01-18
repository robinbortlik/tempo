require 'rails_helper'

RSpec.describe "Navigation", type: :system do
  let(:user) { create(:user, email_address: 'test@example.com', password: 'password123') }

  before do
    # Sign in before each test
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    expect(page).to have_current_path(root_path)
  end

  describe "Desktop Sidebar Navigation" do
    before do
      # Ensure we're in desktop viewport
      page.driver.resize_window_to(page.driver.current_window_handle, 1280, 800)
    end

    it "displays the sidebar with logo" do
      expect(page).to have_css('[data-testid="sidebar"]')
      expect(page).to have_content("Tempo")
    end

    it "displays all main navigation links" do
      within('[data-testid="sidebar"]') do
        expect(page).to have_link("Dashboard")
        expect(page).to have_link("Log Work")
        expect(page).to have_link("Clients")
        expect(page).to have_link("Projects")
        expect(page).to have_link("Invoices")
        expect(page).to have_link("Settings")
        expect(page).to have_css('[data-testid="nav-sign-out"]')
      end
    end

    it "highlights the active navigation item" do
      # Dashboard should be active by default
      within('[data-testid="sidebar"]') do
        dashboard_link = find('[data-testid="nav-dashboard"]')
        expect(dashboard_link[:class]).to include("bg-stone-900")
      end
    end

    it "navigates to Log Work and updates active state" do
      click_link "Log Work"

      expect(page).to have_current_path(work_entries_path)

      within('[data-testid="sidebar"]') do
        log_work_link = find('[data-testid="nav-log-work"]')
        expect(log_work_link[:class]).to include("bg-stone-900")
      end
    end

    it "navigates to Clients page" do
      click_link "Clients"

      expect(page).to have_current_path(clients_path)

      within('[data-testid="sidebar"]') do
        clients_link = find('[data-testid="nav-clients"]')
        expect(clients_link[:class]).to include("bg-stone-900")
      end
    end

    it "navigates to Projects page" do
      click_link "Projects"

      expect(page).to have_current_path(projects_path)

      within('[data-testid="sidebar"]') do
        projects_link = find('[data-testid="nav-projects"]')
        expect(projects_link[:class]).to include("bg-stone-900")
      end
    end

    it "navigates to Invoices page" do
      click_link "Invoices"

      expect(page).to have_current_path(invoices_path)

      within('[data-testid="sidebar"]') do
        invoices_link = find('[data-testid="nav-invoices"]')
        expect(invoices_link[:class]).to include("bg-stone-900")
      end
    end

    it "navigates to Settings page" do
      click_link "Settings"

      expect(page).to have_current_path(settings_path)

      within('[data-testid="sidebar"]') do
        settings_link = find('[data-testid="nav-settings"]')
        expect(settings_link[:class]).to include("bg-stone-900")
      end
    end

    it "can sign out from the sidebar" do
      within('[data-testid="sidebar"]') do
        find('[data-testid="nav-sign-out"]').click
      end

      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "Mobile Navigation" do
    before do
      # Set mobile viewport
      page.driver.resize_window_to(page.driver.current_window_handle, 375, 667)
      # Wait for the page to reflow
      sleep 0.1
    end

    it "displays the mobile header" do
      expect(page).to have_css('[data-testid="mobile-header"]')
    end

    it "displays the hamburger menu button" do
      expect(page).to have_css('[data-testid="mobile-menu-button"]')
    end

    it "hides the desktop sidebar on mobile" do
      # The sidebar should have lg:block class, making it hidden on mobile
      sidebar = find('[data-testid="sidebar"]', visible: false)
      expect(sidebar).not_to be_visible
    end

    it "opens mobile drawer when hamburger menu is clicked" do
      find('[data-testid="mobile-menu-button"]').click

      # Wait for the sheet to open
      expect(page).to have_css('[role="dialog"]')

      # Should see navigation links in the drawer
      within('[role="dialog"]') do
        expect(page).to have_link("Dashboard")
        expect(page).to have_link("Log Work")
        expect(page).to have_link("Clients")
      end
    end

    it "closes mobile drawer when a link is clicked" do
      find('[data-testid="mobile-menu-button"]').click

      within('[role="dialog"]') do
        click_link "Clients"
      end

      expect(page).to have_current_path(clients_path)
      # Drawer should be closed
      expect(page).not_to have_css('[role="dialog"]')
    end

    it "displays user menu button" do
      expect(page).to have_css('[data-testid="user-menu-button"]')
    end

    it "opens user dropdown when user menu is clicked" do
      find('[data-testid="user-menu-button"]').click

      # Should show user email
      expect(page).to have_content(user.email_address)
    end

    it "can sign out from user dropdown" do
      find('[data-testid="user-menu-button"]').click

      # Find and click logout in dropdown
      find('[data-testid="logout-menu-item"]').click

      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "Active State Styling" do
    before do
      page.driver.resize_window_to(page.driver.current_window_handle, 1280, 800)
    end

    it "applies correct styles to active nav item" do
      visit clients_path

      within('[data-testid="sidebar"]') do
        clients_link = find('[data-testid="nav-clients"]')
        expect(clients_link[:class]).to include("bg-stone-900")
        expect(clients_link[:class]).to include("text-white")
      end
    end

    it "applies correct styles to inactive nav items" do
      visit clients_path

      within('[data-testid="sidebar"]') do
        dashboard_link = find('[data-testid="nav-dashboard"]')
        expect(dashboard_link[:class]).to include("text-stone-600")
        expect(dashboard_link[:class]).not_to include("bg-stone-900")
      end
    end

    it "updates active state when navigating between pages" do
      visit clients_path

      within('[data-testid="sidebar"]') do
        # Clients should be active
        expect(find('[data-testid="nav-clients"]')[:class]).to include("bg-stone-900")

        # Click Invoices
        click_link "Invoices"
      end

      expect(page).to have_current_path(invoices_path)

      within('[data-testid="sidebar"]') do
        # Invoices should now be active
        expect(find('[data-testid="nav-invoices"]')[:class]).to include("bg-stone-900")
        # Clients should no longer be active
        expect(find('[data-testid="nav-clients"]')[:class]).not_to include("bg-stone-900")
      end
    end

    it "marks parent route as active for nested pages" do
      # Create a client to visit
      client = create(:client, name: "Test Client")
      visit client_path(client)

      within('[data-testid="sidebar"]') do
        # Clients link should be active even when on client show page
        clients_link = find('[data-testid="nav-clients"]')
        expect(clients_link[:class]).to include("bg-stone-900")
      end
    end
  end
end
