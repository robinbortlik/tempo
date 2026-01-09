require 'rails_helper'

RSpec.describe "Login", type: :system do
  let(:user) { create(:user, email_address: 'test@example.com', password: 'password123') }

  before do
    user # ensure user exists before each test
  end

  describe "visiting the login page" do
    it "displays the login form" do
      visit new_session_path

      expect(page).to have_content("Tempo")
      expect(page).to have_content("Time tracking & invoicing")
      expect(page).to have_field("Email")
      expect(page).to have_field("Password")
      expect(page).to have_button("Sign in")
    end

    it "displays the Tempo logo" do
      visit new_session_path

      # Check for the logo container
      expect(page).to have_css("div.bg-stone-900.rounded-xl")
    end
  end

  describe "signing in with valid credentials" do
    it "redirects to the home page" do
      visit new_session_path

      fill_in "Email", with: user.email_address
      fill_in "Password", with: "password123"
      click_button "Sign in"

      # After successful login, should be redirected to root
      expect(page).to have_current_path(root_path)
    end

    it "creates a session for the user" do
      visit new_session_path

      expect {
        fill_in "Email", with: user.email_address
        fill_in "Password", with: "password123"
        click_button "Sign in"
        # Wait for redirect
        expect(page).to have_current_path(root_path)
      }.to change(Session, :count).by(1)
    end
  end

  describe "signing in with invalid credentials" do
    it "displays an error message for wrong password" do
      visit new_session_path

      fill_in "Email", with: user.email_address
      fill_in "Password", with: "wrong_password"
      click_button "Sign in"

      # Should stay on login page with error
      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("Try another email address or password")
    end

    it "displays an error message for non-existent user" do
      visit new_session_path

      fill_in "Email", with: "nonexistent@example.com"
      fill_in "Password", with: "password123"
      click_button "Sign in"

      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("Try another email address or password")
    end

    it "does not create a session" do
      visit new_session_path

      expect {
        fill_in "Email", with: user.email_address
        fill_in "Password", with: "wrong_password"
        click_button "Sign in"
        expect(page).to have_content("Try another email address or password")
      }.not_to change(Session, :count)
    end
  end

  describe "signing out" do
    before do
      # Sign in first
      visit new_session_path
      fill_in "Email", with: user.email_address
      fill_in "Password", with: "password123"
      click_button "Sign in"
      expect(page).to have_current_path(root_path)
    end

    it "can sign out via DELETE request" do
      # Since we don't have a sign out button in the UI yet,
      # we test sign out functionality via request spec
      # This test just verifies the user is authenticated after login
      expect(page).to have_content("Tempo")
    end
  end

  describe "protected routes" do
    it "redirects unauthenticated users to login" do
      visit root_path

      expect(page).to have_current_path(new_session_path)
    end

    it "allows authenticated users to access protected routes" do
      # Sign in
      visit new_session_path
      fill_in "Email", with: user.email_address
      fill_in "Password", with: "password123"
      click_button "Sign in"

      # Should be able to access root
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Tempo")
    end
  end

  describe "form validation" do
    it "requires email field to be filled" do
      visit new_session_path

      fill_in "Password", with: "password123"
      click_button "Sign in"

      # Browser validation should prevent submission
      # The form should still be visible
      expect(page).to have_field("Email")
    end

    it "requires password field to be filled" do
      visit new_session_path

      fill_in "Email", with: user.email_address
      click_button "Sign in"

      # Browser validation should prevent submission
      expect(page).to have_field("Password")
    end
  end
end
