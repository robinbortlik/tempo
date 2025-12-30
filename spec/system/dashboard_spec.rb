require 'rails_helper'

RSpec.describe "Dashboard", type: :system do
  let(:user) { create(:user) }

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

  describe "dashboard page" do
    it "displays the dashboard page header" do
      visit dashboard_path

      expect(page).to have_content("Dashboard")
      expect(page).to have_content("Overview of your time tracking")
    end

    it "displays all stat cards" do
      visit dashboard_path

      expect(page).to have_content("This Week")
      expect(page).to have_content("This Month")
      expect(page).to have_content("Unbilled Hours")
      expect(page).to have_content("Unbilled Total")
    end

    it "displays chart sections" do
      visit dashboard_path

      expect(page).to have_content("Hours by Client")
      expect(page).to have_content("Monthly Earnings")
      expect(page).to have_content("Hours by Project")
      expect(page).to have_content("Hours Trend")
    end

    it "displays unbilled by client section" do
      visit dashboard_path

      expect(page).to have_content("Unbilled by Client")
      expect(page).to have_content("Create Invoice")
    end
  end

  describe "with time entry data" do
    let!(:client) { create(:client, name: "Acme Corp", currency: "EUR", hourly_rate: 100) }
    let!(:project) { create(:project, client: client, name: "Main Project", hourly_rate: 100) }

    context "with unbilled entries" do
      before do
        create(:time_entry, project: project, date: Date.current, hours: 8, status: :unbilled)
        create(:time_entry, project: project, date: Date.current.beginning_of_week, hours: 4, status: :unbilled)
      end

      it "displays hours this week in stat card" do
        visit dashboard_path

        # The stat cards display hours, just verify the content exists on page
        expect(page).to have_content("12.0")
        expect(page).to have_content("hrs")
      end

      it "displays unbilled amount" do
        visit dashboard_path

        # 12 hours * 100 EUR/hr = 1,200 EUR
        expect(page).to have_content(/1[,.]?200/)
      end

      it "displays client in unbilled table" do
        visit dashboard_path

        within('table') do
          expect(page).to have_content("Acme Corp")
          expect(page).to have_content("12.0")
        end
      end
    end

    context "navigating from dashboard" do
      before do
        create(:time_entry, project: project, date: Date.current, hours: 8, status: :unbilled)
      end

      it "can navigate to create invoice from table" do
        visit dashboard_path

        # Click the Invoice button in the unbilled table
        within('table') do
          click_button "Invoice"
        end

        expect(page).to have_current_path(new_invoice_path, ignore_query: true)
      end

      it "can navigate to client from table row" do
        visit dashboard_path

        # Click on the client name in the table
        within('table') do
          find('td', text: 'Acme Corp').click
        end

        expect(page).to have_current_path(client_path(client))
      end
    end
  end

  describe "with multi-currency data" do
    let!(:eur_client) { create(:client, name: "Euro Client", currency: "EUR", hourly_rate: 100) }
    let!(:usd_client) { create(:client, name: "USD Client", currency: "USD", hourly_rate: 150) }
    let!(:eur_project) { create(:project, client: eur_client, hourly_rate: 100) }
    let!(:usd_project) { create(:project, client: usd_client, hourly_rate: 150) }

    before do
      create(:time_entry, project: eur_project, date: Date.current, hours: 10, status: :unbilled) # 1000 EUR
      create(:time_entry, project: usd_project, date: Date.current, hours: 10, status: :unbilled) # 1500 USD
    end

    it "displays amounts for multiple currencies" do
      visit dashboard_path

      # Should show both EUR and USD amounts
      expect(page).to have_content("EUR")
      expect(page).to have_content("USD")
    end

    it "displays both clients in unbilled table" do
      visit dashboard_path

      within('table') do
        expect(page).to have_content("Euro Client")
        expect(page).to have_content("USD Client")
      end
    end
  end

  describe "empty state" do
    it "shows appropriate empty messages when no data" do
      visit dashboard_path

      expect(page).to have_content("No time entries recorded yet")
    end

    it "shows zero hours in stats" do
      visit dashboard_path

      # When no entries, stats should show 0.0
      expect(page).to have_content("0.0")
    end

    it "shows empty unbilled table message" do
      visit dashboard_path

      expect(page).to have_content("No unbilled time entries")
    end
  end
end
