require 'rails_helper'

RSpec.describe 'Home', type: :request do
  describe 'GET /' do
    before { sign_in }

    it 'returns a successful response' do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the Home Inertia component' do
      get root_path
      expect(response.body).to include('Home')
    end

    it 'includes the message prop' do
      get root_path
      expect(response.body).to include('Time tracking')
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
