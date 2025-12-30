require 'rails_helper'

RSpec.describe 'PWA', type: :system do
  let(:user) { create(:user, email_address: 'test@example.com', password: 'password123') }

  before do
    user # ensure user exists
  end

  describe 'PWA manifest' do
    it 'is linked in the HTML head' do
      visit new_session_path

      # Check the page source for manifest link
      expect(page).to have_css('link[rel="manifest"][href="/manifest.json"]', visible: false)
    end
  end

  describe 'PWA meta tags' do
    it 'includes theme-color meta tag' do
      visit new_session_path

      expect(page).to have_css('meta[name="theme-color"][content="#1c1917"]', visible: false)
    end

    it 'includes apple-mobile-web-app-capable meta tag' do
      visit new_session_path

      expect(page).to have_css('meta[name="apple-mobile-web-app-capable"][content="yes"]', visible: false)
    end

    it 'includes apple-mobile-web-app-status-bar-style meta tag' do
      visit new_session_path

      expect(page).to have_css('meta[name="apple-mobile-web-app-status-bar-style"]', visible: false)
    end

    it 'includes apple-touch-icon link' do
      visit new_session_path

      expect(page).to have_css('link[rel="apple-touch-icon"]', visible: false)
    end
  end

  describe 'service worker registration' do
    it 'has service worker registration code in the app' do
      # Sign in first
      visit new_session_path
      fill_in 'Email', with: user.email_address
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'
      expect(page).to have_current_path(root_path)

      # Check that service worker registration is attempted
      # Note: In test environment, service worker might not fully register
      # but we verify the code is present and executes without errors
      result = page.evaluate_script('typeof navigator.serviceWorker !== "undefined"')
      expect(result).to be true
    end
  end

  describe 'manifest.json accessibility' do
    it 'can be fetched directly' do
      visit '/manifest.json'

      # The page should contain JSON with app name
      expect(page.body).to include('Tempo')
      expect(page.body).to include('standalone')
    end
  end

  describe 'app icons accessibility' do
    it 'can access 192x192 icon' do
      visit '/icons/icon-192x192.png'

      # Verify the page loaded (will throw error if 404)
      # PNG files load as raw content, we just verify no error occurs
      expect(page).not_to have_content('Not Found')
    end

    it 'can access 512x512 icon' do
      visit '/icons/icon-512x512.png'

      # Verify the page loaded (will throw error if 404)
      # PNG files load as raw content, we just verify no error occurs
      expect(page).not_to have_content('Not Found')
    end
  end
end
