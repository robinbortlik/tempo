require 'rails_helper'

RSpec.describe 'Home', type: :request do
  describe 'GET /' do
    before { sign_in }

    it 'returns a successful response' do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the Dashboard Inertia component' do
      get root_path
      expect(response.body).to include('Dashboard/Index')
    end

    it 'includes the stats and charts props' do
      get root_path, headers: { 'X-Inertia' => 'true', 'X-Inertia-Version' => ViteRuby.digest }
      json_response = JSON.parse(response.body)
      expect(json_response['props']).to include('stats', 'charts')
    end

    it 'uses the inertia layout' do
      get root_path
      expect(response.body).to include('<!DOCTYPE html>')
      expect(response.body).to include('application-name')
    end
  end

  describe 'GET / unauthenticated' do
    it 'redirects to login' do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
