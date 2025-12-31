require 'rails_helper'

RSpec.describe "Projects", type: :system do
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

  describe "projects index page" do
    it "displays the projects page header" do
      visit projects_path

      expect(page).to have_content("Projects")
      expect(page).to have_content("Manage your projects across clients")
      expect(page).to have_button("Add Project")
    end

    it "displays empty state when no projects exist" do
      visit projects_path

      expect(page).to have_content("No projects yet")
    end

    context "with existing projects grouped by client" do
      let!(:client1) { create(:client, name: "Acme Corp", currency: "EUR", hourly_rate: 120) }
      let!(:client2) { create(:client, name: "TechStart", currency: "USD", hourly_rate: 100) }
      let!(:project1) { create(:project, client: client1, name: "API Integration", hourly_rate: 150, active: true) }
      let!(:project2) { create(:project, client: client1, name: "Mobile App", active: true) }
      let!(:project3) { create(:project, client: client2, name: "Dashboard", active: false) }

      it "displays projects grouped by client" do
        visit projects_path

        # Client headers
        expect(page).to have_content("Acme Corp")
        expect(page).to have_content("TechStart")

        # Projects
        expect(page).to have_content("API Integration")
        expect(page).to have_content("Mobile App")
        expect(page).to have_content("Dashboard")
      end

      it "shows project count per client" do
        visit projects_path

        expect(page).to have_content("2 projects")
        expect(page).to have_content("1 project")
      end

      it "navigates to project details when clicking a project" do
        visit projects_path

        find('p', text: 'API Integration').click

        expect(page).to have_current_path(project_path(project1))
        expect(page).to have_content("API Integration")
      end

      it "shows custom rate indicator for projects with custom rates" do
        visit projects_path

        # API Integration has custom rate of 150
        expect(page).to have_content("(custom rate)")
      end

      context "with unbilled time entries" do
        before do
          create(:work_entry, project: project1, hours: 8, status: :unbilled)
          create(:work_entry, project: project1, hours: 4, status: :unbilled)
        end

        it "shows unbilled hours for projects" do
          visit projects_path

          expect(page).to have_content("unbilled")
          expect(page).to have_content("12")
        end
      end
    end
  end

  describe "creating a new project" do
    let!(:client) { create(:client, name: "Acme Corp", currency: "EUR", hourly_rate: 120) }

    it "navigates to new project page when clicking Add Project" do
      visit projects_path

      # Click the first Add Project button (in the header)
      first(:button, "Add Project").click

      expect(page).to have_current_path(new_project_path)
      expect(page).to have_content("New Project")
      expect(page).to have_content("Add a new project to track time")
    end

    it "creates a project with valid data" do
      visit new_project_path

      fill_in "Project Name", with: "Website Redesign"
      select "Acme Corp", from: "Client"
      fill_in "Custom Hourly Rate", with: "150"

      click_button "Create Project"

      expect(page).to have_content("Project created successfully")
      expect(page).to have_content("Website Redesign")
    end

    it "creates a project without custom rate (uses client rate)" do
      visit new_project_path

      fill_in "Project Name", with: "API Project"
      select "Acme Corp", from: "Client"
      # Leave hourly rate empty

      click_button "Create Project"

      expect(page).to have_content("Project created successfully")
      expect(page).to have_content("API Project")
    end

    it "disables submit button when name is empty" do
      visit new_project_path

      select "Acme Corp", from: "Client"
      # Leave name empty

      expect(page).to have_button("Create Project", disabled: true)
    end

    it "disables submit button when client is not selected" do
      visit new_project_path

      fill_in "Project Name", with: "Test Project"
      # Leave client unselected

      expect(page).to have_button("Create Project", disabled: true)
    end

    it "navigates back to projects list when clicking Back" do
      visit new_project_path

      click_on "Back to Projects"

      expect(page).to have_current_path(projects_path)
    end

    context "when coming from client page" do
      it "pre-selects the client" do
        visit new_project_path(client_id: client.id)

        # Check that the select shows Acme Corp as the selected value
        select_element = find("select#client_id")
        selected_text = select_element.find("option[value='#{client.id}']").text
        expect(selected_text).to include("Acme Corp")
      end
    end
  end

  describe "viewing a project" do
    let!(:client) { create(:client, name: "Acme Corp", currency: "EUR", hourly_rate: 120) }
    let!(:project) { create(:project, client: client, name: "API Integration", hourly_rate: 150, active: true) }

    it "displays project header with details" do
      visit project_path(project)

      expect(page).to have_content("API Integration")
      expect(page).to have_content("Acme Corp")
      expect(page).to have_content("(custom rate)")
      expect(page).to have_button("Edit")
      expect(page).to have_button("Delete")
    end

    it "displays stats cards" do
      visit project_path(project)

      expect(page).to have_content("Total Hours")
      expect(page).to have_content("Unbilled Hours")
      expect(page).to have_content("Unbilled Amount")
    end

    it "displays empty work entries message" do
      visit project_path(project)

      expect(page).to have_content("No work entries yet")
    end

    it "navigates back to projects list" do
      visit project_path(project)

      click_on "Back to Projects"

      expect(page).to have_current_path(projects_path)
    end

    context "with time entries" do
      let!(:entry1) { create(:work_entry, project: project, date: Date.current, hours: 8, description: "Working on API", status: :unbilled) }
      let!(:entry2) { create(:work_entry, project: project, date: Date.yesterday, hours: 4, description: "Code review", status: :invoiced) }

      it "displays time entries in the table" do
        visit project_path(project)

        expect(page).to have_content("Working on API")
        expect(page).to have_content("Code review")
        # Hours display with decimal format
        expect(page).to have_content("8")
        expect(page).to have_content("4")
      end

      it "shows correct status badges" do
        visit project_path(project)

        expect(page).to have_content("Unbilled")
        expect(page).to have_content("Invoiced")
      end

      it "shows correct stats" do
        visit project_path(project)

        # Total hours: 12 (8 + 4)
        expect(page).to have_content("12")
        # Unbilled hours: 8
        expect(page).to have_content("8")
      end
    end
  end

  describe "editing a project" do
    let!(:client) { create(:client, name: "Acme Corp") }
    let!(:client2) { create(:client, name: "TechStart") }
    let!(:project) { create(:project, client: client, name: "Original Project", hourly_rate: 100) }

    it "displays the edit form with existing data" do
      visit edit_project_path(project)

      expect(page).to have_content("Edit Project")
      expect(page).to have_field("Project Name", with: "Original Project")
      expect(page).to have_field("Custom Hourly Rate", with: "100.0")
    end

    it "updates the project with valid data" do
      visit edit_project_path(project)

      fill_in "Project Name", with: "Updated Project", fill_options: { clear: :backspace }
      fill_in "Custom Hourly Rate", with: "200", fill_options: { clear: :backspace }

      click_button "Save Changes"

      expect(page).to have_content("Project updated successfully")
      expect(page).to have_content("Updated Project")
    end

    it "navigates back to project details when clicking Back" do
      visit edit_project_path(project)

      click_on "Back to Original Project"

      expect(page).to have_current_path(project_path(project))
    end

    it "can cancel editing" do
      visit edit_project_path(project)

      click_button "Cancel"

      expect(page).to have_current_path(project_path(project))
    end
  end

  describe "toggling project active status" do
    let!(:client) { create(:client, name: "Acme Corp") }
    let!(:active_project) { create(:project, client: client, name: "Active Project", active: true) }
    let!(:inactive_project) { create(:project, client: client, name: "Inactive Project", active: false) }

    it "deactivates an active project" do
      visit project_path(active_project)

      click_button "Deactivate"

      expect(page).to have_content("deactivated successfully")
      expect(page).to have_button("Activate")
    end

    it "activates an inactive project" do
      visit project_path(inactive_project)

      click_button "Activate"

      expect(page).to have_content("activated successfully")
      expect(page).to have_button("Deactivate")
    end
  end

  describe "deleting a project" do
    let!(:client) { create(:client, name: "Acme Corp") }
    let!(:project) { create(:project, client: client, name: "Project To Delete") }

    it "shows delete confirmation dialog" do
      visit project_path(project)

      click_button "Delete"

      expect(page).to have_content("Delete Project To Delete?")
      expect(page).to have_content("This action cannot be undone")
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Delete")
    end

    it "deletes the project when confirmed" do
      visit project_path(project)

      click_button "Delete"

      within('[role="alertdialog"]') do
        click_button "Delete"
      end

      expect(page).to have_current_path(projects_path)
      expect(page).to have_content("Project deleted successfully")
      expect(page).not_to have_content("Project To Delete")
    end

    it "can cancel deletion" do
      visit project_path(project)

      click_button "Delete"

      within('[role="alertdialog"]') do
        click_button "Cancel"
      end

      expect(page).to have_current_path(project_path(project))
      expect(page).to have_content("Project To Delete")
    end

    context "with invoiced time entries" do
      before do
        create(:work_entry, project: project, status: :invoiced)
      end

      it "shows error when trying to delete project with invoiced entries" do
        visit project_path(project)

        click_button "Delete"

        within('[role="alertdialog"]') do
          click_button "Delete"
        end

        expect(page).to have_content("Cannot delete project with invoiced work entries")
      end
    end
  end

  describe "page styling" do
    let!(:client) { create(:client) }
    let!(:project) { create(:project, client: client) }

    it "uses the correct styling on index page" do
      visit projects_path

      expect(page).to have_css(".bg-white.rounded-xl.border")
    end

    it "uses the correct styling on show page" do
      visit project_path(project)

      # Stats cards
      expect(page).to have_css(".bg-white.rounded-xl.border")
      expect(page).to have_css(".bg-amber-50.border-amber-200")
    end

    it "uses the correct styling on form pages" do
      visit new_project_path

      expect(page).to have_css(".bg-white.rounded-xl.border")
      expect(page).to have_css(".bg-stone-50")
    end
  end
end
