require 'rails_helper'

RSpec.describe 'PWA', type: :request do
  describe 'GET /manifest.json' do
    it 'returns a successful response' do
      get '/manifest.json'
      expect(response).to have_http_status(:success)
    end

    it 'returns JSON content type' do
      get '/manifest.json'
      expect(response.content_type).to include('application/json')
    end

    it 'includes required PWA manifest fields' do
      get '/manifest.json'
      manifest = JSON.parse(response.body)

      expect(manifest['name']).to eq('Tempo')
      expect(manifest['short_name']).to eq('Tempo')
      expect(manifest['start_url']).to eq('/')
      expect(manifest['display']).to eq('standalone')
      expect(manifest['theme_color']).to eq('#1c1917')
      expect(manifest['background_color']).to eq('#ffffff')
    end

    it 'includes icons array with required sizes' do
      get '/manifest.json'
      manifest = JSON.parse(response.body)

      expect(manifest['icons']).to be_an(Array)
      expect(manifest['icons'].length).to be >= 2

      sizes = manifest['icons'].map { |icon| icon['sizes'] }
      expect(sizes).to include('192x192')
      expect(sizes).to include('512x512')
    end
  end

  describe 'GET /service-worker.js' do
    it 'returns a successful response' do
      get '/service-worker.js'
      expect(response).to have_http_status(:success)
    end

    it 'returns JavaScript content type' do
      get '/service-worker.js'
      expect(response.content_type).to include('javascript')
    end

    it 'includes service worker event listeners' do
      get '/service-worker.js'
      content = response.body

      expect(content).to include("addEventListener('install'")
      expect(content).to include("addEventListener('activate'")
      expect(content).to include("addEventListener('fetch'")
    end

    it 'includes cache name configuration' do
      get '/service-worker.js'
      content = response.body

      expect(content).to include('CACHE_NAME')
      expect(content).to include('tempo')
    end
  end

  describe 'GET /icons/icon-192x192.png' do
    it 'returns a successful response' do
      get '/icons/icon-192x192.png'
      expect(response).to have_http_status(:success)
    end

    it 'returns PNG content type' do
      get '/icons/icon-192x192.png'
      expect(response.content_type).to include('image/png')
    end
  end

  describe 'GET /icons/icon-512x512.png' do
    it 'returns a successful response' do
      get '/icons/icon-512x512.png'
      expect(response).to have_http_status(:success)
    end

    it 'returns PNG content type' do
      get '/icons/icon-512x512.png'
      expect(response.content_type).to include('image/png')
    end
  end

  describe 'HTML head includes PWA requirements' do
    before { sign_in }

    it 'includes manifest link' do
      get root_path
      expect(response.body).to include('rel="manifest"')
      expect(response.body).to include('/manifest.json')
    end

    it 'includes theme-color meta tag' do
      get root_path
      expect(response.body).to include('name="theme-color"')
      expect(response.body).to include('#1c1917')
    end

    it 'includes iOS Safari meta tags' do
      get root_path
      expect(response.body).to include('name="apple-mobile-web-app-capable"')
      expect(response.body).to include('name="apple-mobile-web-app-status-bar-style"')
      expect(response.body).to include('name="apple-mobile-web-app-title"')
    end

    it 'includes apple-touch-icon' do
      get root_path
      expect(response.body).to include('rel="apple-touch-icon"')
      expect(response.body).to include('/icons/icon-192x192.png')
    end
  end
end
