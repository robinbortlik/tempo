require 'rails_helper'

RSpec.describe 'layouts/inertia', type: :view do
  before do
    render template: 'layouts/inertia', layout: false
  end

  it 'renders a valid HTML document' do
    expect(rendered).to include('<!DOCTYPE html>')
    expect(rendered).to include('<html lang="en">')
  end

  it 'includes viewport meta tag for responsive design' do
    expect(rendered).to include('name="viewport"')
    expect(rendered).to include('width=device-width')
  end

  it 'includes PWA meta tags' do
    expect(rendered).to include('name="apple-mobile-web-app-capable"')
    expect(rendered).to include('name="apple-mobile-web-app-status-bar-style"')
    expect(rendered).to include('name="apple-mobile-web-app-title"')
    expect(rendered).to include('name="mobile-web-app-capable"')
    expect(rendered).to include('name="application-name"')
    expect(rendered).to include('name="theme-color"')
    expect(rendered).to include('#1c1917')
    expect(rendered).to include('Tempo')
  end

  it 'includes PWA manifest link' do
    expect(rendered).to include('rel="manifest"')
    expect(rendered).to include('/manifest.json')
  end

  # Note: CSRF meta tags are tested via request specs since they require request context
  it 'includes template for CSRF meta tags' do
    # The layout includes csrf_meta_tags helper call (verified by reading the template)
    expect(File.read(Rails.root.join('app/views/layouts/inertia.html.erb'))).to include('csrf_meta_tags')
  end

  it 'includes favicon links' do
    expect(rendered).to include('rel="icon"')
    expect(rendered).to include('rel="apple-touch-icon"')
  end

  it 'includes Vite client and application tags' do
    expect(rendered).to include('vite')
  end
end
