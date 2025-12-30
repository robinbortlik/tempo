require 'rails_helper'

RSpec.describe "Time Entries", type: :system do
  let(:user) { create(:user) }

  before do
    Capybara.reset_sessions!

    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    # Wait for redirect to complete with a more forgiving check
    expect(page).to have_current_path(root_path, wait: 5)
  end

  describe "time entries index page" do
    it "displays the time entries page header" do
      visit time_entries_path

      expect(page).to have_content("Time Entries")
      expect(page).to have_content("Track your work")
    end

    it "displays empty state when no time entries exist" do
      visit time_entries_path

      expect(page).to have_content("No time entries found")
    end

    it "displays the Quick Entry form" do
      visit time_entries_path

      expect(page).to have_content("Quick Entry")
      expect(page).to have_field("Date")
      expect(page).to have_field("Project")
      expect(page).to have_field("Hours")
      expect(page).to have_field("Description")
      # Button is disabled when form is empty
      expect(page).to have_button("Add Entry", disabled: true)
    end

    it "displays the filter section" do
      visit time_entries_path

      expect(page).to have_content("Filters")
      expect(page).to have_field("Start Date")
      expect(page).to have_field("End Date")
      expect(page).to have_button("Apply Filters")
    end
  end

  describe "viewing time entries grouped by date" do
    let!(:client) { create(:client, name: "Acme Corp", currency: "EUR") }
    let!(:project) { create(:project, client: client, name: "API Integration") }
    let!(:entry_today) { create(:time_entry, project: project, date: Date.current, hours: 8, description: "Working on API", status: :unbilled) }
    let!(:entry_yesterday) { create(:time_entry, project: project, date: Date.yesterday, hours: 4, description: "Code review", status: :unbilled) }

    it "displays entries grouped by date" do
      visit time_entries_path

      expect(page).to have_content("Today")
      expect(page).to have_content("Yesterday")
    end

    it "displays entry details" do
      visit time_entries_path

      expect(page).to have_content("Acme Corp")
      expect(page).to have_content("API Integration")
      expect(page).to have_content("Working on API")
      expect(page).to have_content("8h")
    end

    it "displays total hours for each date group" do
      visit time_entries_path

      expect(page).to have_content("8 hours")
      expect(page).to have_content("4 hours")
    end
  end

  describe "status badges" do
    let!(:client) { create(:client, name: "Acme Corp") }
    let!(:project) { create(:project, client: client, name: "API Project") }
    let!(:unbilled_entry) { create(:time_entry, project: project, date: Date.current, status: :unbilled) }
    let!(:invoiced_entry) { create(:time_entry, project: project, date: Date.yesterday, status: :invoiced) }

    it "shows Unbilled badge for unbilled entries" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{unbilled_entry.id}']") do
        expect(page).to have_content("Unbilled")
      end
    end

    it "shows Invoiced badge for invoiced entries" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{invoiced_entry.id}']") do
        expect(page).to have_content("Invoiced")
      end
    end
  end

  describe "edit/delete buttons for entries" do
    let!(:client) { create(:client, name: "Acme Corp") }
    let!(:project) { create(:project, client: client, name: "API Project") }
    let!(:unbilled_entry) { create(:time_entry, project: project, date: Date.current, status: :unbilled, description: "Unbilled work") }
    let!(:invoiced_entry) { create(:time_entry, project: project, date: Date.yesterday, status: :invoiced, description: "Invoiced work") }

    it "shows edit and delete buttons for unbilled entries" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{unbilled_entry.id}']") do
        expect(page).to have_css("[data-testid='edit-entry-#{unbilled_entry.id}']")
        expect(page).to have_css("[data-testid='delete-entry-#{unbilled_entry.id}']")
      end
    end

    it "does not show edit and delete buttons for invoiced entries" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{invoiced_entry.id}']") do
        expect(page).not_to have_css("[data-testid='edit-entry-#{invoiced_entry.id}']")
        expect(page).not_to have_css("[data-testid='delete-entry-#{invoiced_entry.id}']")
      end
    end
  end

  describe "creating a new time entry" do
    let!(:client) { create(:client, name: "Acme Corp") }
    let!(:project) { create(:project, client: client, name: "API Integration", active: true) }

    it "creates a time entry with valid data" do
      visit time_entries_path

      today = Date.current.strftime("%Y-%m-%d")

      within('.bg-white.rounded-xl.border', match: :first) do
        fill_in "Date", with: today
        select "Acme Corp", from: "Project"
        fill_in "Hours", with: "6"
        fill_in "Description", with: "New feature development"
        click_button "Add Entry"
      end

      expect(page).to have_content("Time entry created successfully")
      expect(page).to have_content("New feature development")
      expect(page).to have_content("6h")
    end

    it "disables submit button when form is incomplete" do
      visit time_entries_path

      expect(page).to have_button("Add Entry", disabled: true)
    end
  end

  describe "editing an unbilled entry" do
    let!(:client) { create(:client, name: "Acme Corp") }
    let!(:project) { create(:project, client: client, name: "API Project", active: true) }
    let!(:entry) { create(:time_entry, project: project, date: Date.current, hours: 8, description: "Original work", status: :unbilled) }

    it "transforms row into inline edit form when clicking edit" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{entry.id}']") do
        find("[data-testid='edit-entry-#{entry.id}']").click
      end

      within("[data-testid='time-entry-row-#{entry.id}']") do
        expect(page).to have_field(type: "date")
        expect(page).to have_field(type: "number")
        expect(page).to have_button("Save")
        expect(page).to have_button("Cancel")
      end
    end

    it "saves the edited entry" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{entry.id}']") do
        find("[data-testid='edit-entry-#{entry.id}']").click
      end

      within("[data-testid='time-entry-row-#{entry.id}']") do
        fill_in type: "number", with: "10"
        click_button "Save"
      end

      expect(page).to have_content("Time entry updated successfully")
      expect(page).to have_content("10h")
    end

    it "cancels editing without saving changes" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{entry.id}']") do
        find("[data-testid='edit-entry-#{entry.id}']").click
        fill_in type: "number", with: "10"
        click_button "Cancel"
      end

      within("[data-testid='time-entry-row-#{entry.id}']") do
        expect(page).to have_content("8h")
        expect(page).not_to have_button("Save")
      end
    end
  end

  describe "deleting an unbilled entry" do
    let!(:client) { create(:client, name: "Acme Corp") }
    let!(:project) { create(:project, client: client, name: "API Project") }
    let!(:entry) { create(:time_entry, project: project, date: Date.current, description: "Work to delete", status: :unbilled) }

    it "shows delete confirmation dialog" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{entry.id}']") do
        find("[data-testid='delete-entry-#{entry.id}']").click
      end

      expect(page).to have_content("Delete Time Entry?")
      expect(page).to have_content("This action cannot be undone")
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Delete")
    end

    it "deletes the entry when confirmed" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{entry.id}']") do
        find("[data-testid='delete-entry-#{entry.id}']").click
      end

      within('[role="alertdialog"]') do
        click_button "Delete"
      end

      expect(page).to have_content("Time entry deleted successfully")
      expect(page).not_to have_content("Work to delete")
    end

    it "can cancel deletion" do
      visit time_entries_path

      within("[data-testid='time-entry-row-#{entry.id}']") do
        find("[data-testid='delete-entry-#{entry.id}']").click
      end

      within('[role="alertdialog"]') do
        click_button "Cancel"
      end

      expect(page).to have_content("Work to delete")
    end
  end

  describe "filtering time entries" do
    let!(:client1) { create(:client, name: "Acme Corp") }
    let!(:client2) { create(:client, name: "TechStart") }
    let!(:project1) { create(:project, client: client1, name: "API Project", active: true) }
    let!(:project2) { create(:project, client: client2, name: "Dashboard", active: true) }
    let!(:entry1) { create(:time_entry, project: project1, date: Date.current, description: "Acme work") }
    let!(:entry2) { create(:time_entry, project: project2, date: Date.yesterday, description: "TechStart work") }

    it "filters by client" do
      visit time_entries_path

      select "Acme Corp", from: "filter-client"
      click_button "Apply Filters"

      expect(page).to have_content("Acme work")
      expect(page).not_to have_content("TechStart work")
    end

    it "filters by project" do
      visit time_entries_path

      select "TechStart", from: "filter-client"
      select "TechStart", from: "filter-project"
      click_button "Apply Filters"

      expect(page).to have_content("TechStart work")
      expect(page).not_to have_content("Acme work")
    end

    it "filters by date range" do
      visit time_entries_path

      # Verify both entries are visible before filtering
      expect(page).to have_content("Acme work")
      expect(page).to have_content("TechStart work")

      # Filter to today only (entry1 is today, entry2 is yesterday)
      today = entry1.date.strftime("%Y-%m-%d")

      # Set date values and dispatch input events for React to pick up the change
      page.execute_script(<<~JS)
        const startInput = document.getElementById('filter-start-date');
        const endInput = document.getElementById('filter-end-date');

        const nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;

        nativeInputValueSetter.call(startInput, '#{today}');
        startInput.dispatchEvent(new Event('input', { bubbles: true }));

        nativeInputValueSetter.call(endInput, '#{today}');
        endInput.dispatchEvent(new Event('input', { bubbles: true }));
      JS

      click_button "Apply Filters"

      expect(page).to have_content("Acme work")
      expect(page).not_to have_content("TechStart work")
    end

    it "clears all filters" do
      visit time_entries_path

      select "Acme Corp", from: "filter-client"
      click_button "Apply Filters"

      expect(page).not_to have_content("TechStart work")

      click_on "Clear all"

      expect(page).to have_content("Acme work")
      expect(page).to have_content("TechStart work")
    end
  end

  describe "page styling" do
    let!(:client) { create(:client) }
    let!(:project) { create(:project, client: client) }
    let!(:entry) { create(:time_entry, project: project) }

    it "uses the correct card styling" do
      visit time_entries_path

      expect(page).to have_css(".bg-white.rounded-xl.border")
    end

    it "uses correct status badge colors" do
      visit time_entries_path

      expect(page).to have_css(".bg-amber-100.text-amber-700")
    end
  end
end
