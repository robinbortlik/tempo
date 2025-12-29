require 'rails_helper'

RSpec.describe 'InertiaRails Configuration', type: :request do
  describe 'configuration' do
    it 'has default_render enabled' do
      expect(InertiaRails.configuration.default_render).to be true
    end

    it 'always includes errors hash' do
      expect(InertiaRails.configuration.always_include_errors_hash).to be true
    end

    it 'uses ViteRuby digest for versioning' do
      expect(InertiaRails.configuration.version).to eq(ViteRuby.digest)
    end
  end

  describe 'Inertia response' do
    it 'responds to regular requests with full HTML' do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/html')
    end

    it 'responds to Inertia requests with JSON' do
      get root_path, headers: { 'X-Inertia' => 'true', 'X-Inertia-Version' => ViteRuby.digest }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
    end

    it 'includes component name in Inertia response' do
      get root_path, headers: { 'X-Inertia' => 'true', 'X-Inertia-Version' => ViteRuby.digest }
      json_response = JSON.parse(response.body)
      expect(json_response['component']).to eq('Home')
    end

    it 'includes props in Inertia response' do
      get root_path, headers: { 'X-Inertia' => 'true', 'X-Inertia-Version' => ViteRuby.digest }
      json_response = JSON.parse(response.body)
      expect(json_response['props']).to include('message')
    end

    it 'includes url in Inertia response' do
      get root_path, headers: { 'X-Inertia' => 'true', 'X-Inertia-Version' => ViteRuby.digest }
      json_response = JSON.parse(response.body)
      expect(json_response['url']).to eq('/')
    end

    it 'includes version in Inertia response' do
      get root_path, headers: { 'X-Inertia' => 'true', 'X-Inertia-Version' => ViteRuby.digest }
      json_response = JSON.parse(response.body)
      expect(json_response['version']).to eq(ViteRuby.digest)
    end
  end

  describe 'version mismatch handling' do
    it 'returns 409 Conflict when version does not match' do
      get root_path, headers: { 'X-Inertia' => 'true', 'X-Inertia-Version' => 'outdated-version' }
      expect(response).to have_http_status(:conflict)
    end
  end
end
