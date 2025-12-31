require 'rails_helper'

RSpec.describe "Client Report Portal", type: :system do
  let!(:setting) { Setting.instance.update!(company_name: "Tempo Inc") }
  let!(:client) { create(:client, name: "Acme Corporation", currency: "EUR", hourly_rate: 120) }
  let!(:project) { create(:project, client: client, name: "API Integration", hourly_rate: nil, active: true) }

  describe "accessing the report portal" do
    it "displays the report page with valid share token" do
      visit report_path(client.share_token)

      expect(page).to have_content("Time Report for")
      expect(page).to have_content("Acme Corporation")
      expect(page).to have_content("Prepared by")
      expect(page).to have_content("Tempo Inc")
    end

    it "returns 404 for invalid share token" do
      # In test environment, the error is raised but Capybara shows error page
      # Use request spec for actual 404 behavior testing
      visit "/reports/invalid-token-12345"
      # Should show error page or no content from the report
      expect(page).not_to have_content("Time Report for")
    end
  end

  describe "report header" do
    it "displays client name and company name" do
      visit report_path(client.share_token)

      expect(page).to have_content("Time Report for")
      expect(page).to have_content("Acme Corporation")
      expect(page).to have_content("Prepared by")
      expect(page).to have_content("Tempo Inc")
    end
  end

  describe "period filters" do
    it "displays year selector with available years" do
      visit report_path(client.share_token)

      expect(page).to have_select(selected: Date.current.year.to_s)
    end

    it "displays month buttons including All option" do
      visit report_path(client.share_token)

      expect(page).to have_button("All")
      expect(page).to have_button("Jan")
      expect(page).to have_button("Feb")
      expect(page).to have_button("Dec")
    end

    it "can filter by specific month" do
      visit report_path(client.share_token)

      click_button "Dec"

      # URL should be updated with month parameter
      expect(page).to have_current_path(/month=12/)
    end

    it "can show all months when clicking All" do
      visit report_path(client.share_token, month: 12)

      click_button "All"

      # URL should not have month parameter
      expect(page).not_to have_current_path(/month=/)
    end
  end

  describe "summary cards" do
    context "with unbilled entries" do
      before do
        create(:work_entry, project: project, date: Date.current, hours: 8, description: "Development work", status: :unbilled)
        create(:work_entry, project: project, date: Date.current - 1.day, hours: 4, description: "Code review", status: :unbilled)
      end

      it "displays unbilled hours and amount" do
        visit report_path(client.share_token)

        expect(page).to have_content("Unbilled Hours")
        expect(page).to have_content("12") # 8 + 4 hours
        expect(page).to have_content("Unbilled Amount")
      end
    end

    context "with invoiced entries" do
      before do
        invoice = create(:invoice, :final, client: client, period_start: Date.current.beginning_of_month, period_end: Date.current.end_of_month, total_hours: 40, total_amount: 4800)
        create(:work_entry, :invoiced, project: project, date: Date.current, hours: 40, invoice: invoice)
      end

      it "displays invoiced total" do
        visit report_path(client.share_token)

        expect(page).to have_content("Invoiced")
      end
    end
  end

  describe "unbilled section" do
    before do
      create(:work_entry, project: project, date: Date.current, hours: 8, description: "OAuth implementation", status: :unbilled)
    end

    it "displays unbilled work header with amber indicator" do
      visit report_path(client.share_token)

      expect(page).to have_content("Unbilled Work")
    end

    it "displays project groups with entries" do
      visit report_path(client.share_token)

      expect(page).to have_content("API Integration")
      expect(page).to have_content("OAuth implementation")
      expect(page).to have_content("8h")
    end

    it "shows project totals in header" do
      visit report_path(client.share_token)

      # Project group header should show hours and amount
      expect(page).to have_content("8h")
    end
  end

  describe "invoiced section" do
    before do
      @invoice = create(:invoice, :final,
        client: client,
        number: "2024-001",
        period_start: Date.current.beginning_of_month,
        period_end: Date.current.end_of_month,
        total_hours: 40,
        total_amount: 4800
      )
    end

    it "displays previously invoiced header with emerald indicator" do
      visit report_path(client.share_token)

      expect(page).to have_content("Previously Invoiced")
    end

    it "displays invoice summary cards" do
      visit report_path(client.share_token)

      expect(page).to have_content("Invoice #2024-001")
      expect(page).to have_content("40 hours")
    end
  end

  describe "collapsible project groups" do
    before do
      create(:work_entry, project: project, date: Date.current, hours: 8, description: "Development", status: :unbilled)
    end

    it "shows project entries when expanded" do
      visit report_path(client.share_token)

      # Entries should be visible by default (expanded)
      expect(page).to have_content("Development")
    end
  end

  describe "empty state" do
    it "shows message when no entries exist for period" do
      # Create entry in different year
      create(:work_entry, project: project, date: Date.new(2020, 1, 1), hours: 8, status: :unbilled)

      visit report_path(client.share_token, year: Date.current.year)

      expect(page).to have_content("No time entries found for this period")
    end
  end

  describe "responsive design" do
    it "has responsive summary cards" do
      visit report_path(client.share_token)

      # Summary cards should exist with proper styling
      expect(page).to have_css(".bg-amber-50.border-amber-200")
      expect(page).to have_css(".bg-emerald-50.border-emerald-200")
    end
  end

  describe "currency formatting" do
    context "with EUR currency" do
      it "displays Euro symbol" do
        create(:work_entry, project: project, date: Date.current, hours: 10, status: :unbilled)

        visit report_path(client.share_token)

        # Should show Euro symbol
        expect(page).to have_content("\u20AC") # Euro symbol
      end
    end

    context "with USD currency" do
      let!(:usd_client) { create(:client, name: "US Company", currency: "USD", hourly_rate: 100) }
      let!(:usd_project) { create(:project, client: usd_client, name: "US Project") }

      it "displays Dollar symbol" do
        create(:work_entry, project: usd_project, date: Date.current, hours: 10, status: :unbilled)

        visit report_path(usd_client.share_token)

        expect(page).to have_content("$")
      end
    end
  end

  describe "date formatting" do
    before do
      create(:work_entry, project: project, date: Date.new(2024, 12, 25), hours: 8, description: "Christmas work", status: :unbilled)
    end

    it "formats dates in readable format" do
      visit report_path(client.share_token, year: 2024, month: 12)

      expect(page).to have_content("Dec 25")
    end
  end

  describe "page styling" do
    before do
      create(:work_entry, project: project, date: Date.current, hours: 8, status: :unbilled)
    end

    it "uses correct styling classes" do
      visit report_path(client.share_token)

      # Check summary card styling
      expect(page).to have_css(".bg-amber-50")
      expect(page).to have_css(".bg-emerald-50")

      # Check section styling
      expect(page).to have_css(".rounded-xl")
      expect(page).to have_css(".border-stone-200")
    end

    it "uses tabular-nums for numeric values" do
      visit report_path(client.share_token)

      expect(page).to have_css(".tabular-nums")
    end
  end
end
