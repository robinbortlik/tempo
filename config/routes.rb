Rails.application.routes.draw do
  # Public client report portal (no authentication required)
  get "reports/:share_token", to: "reports#show", as: :report
  get "reports/:share_token/invoices/:invoice_id/pdf", to: "reports#invoice_pdf", as: :report_invoice_pdf

  resource :session
  resource :settings, only: [ :show, :update ] do
    patch :locale, to: "settings#update_locale", on: :member
  end
  resource :dashboard, only: [ :show ], controller: "dashboard" do
    get :time_by_client, on: :member
    get :time_by_project, on: :member
    get :earnings_over_time, on: :member
    get :hours_trend, on: :member
  end
  resources :clients do
    member do
      patch :toggle_sharing
      patch :regenerate_share_token
    end
  end
  resources :projects do
    member do
      patch :toggle_active
    end
  end
  resources :work_entries, only: [ :index, :create, :update, :destroy ] do
    collection do
      delete :bulk_destroy
    end
  end
  resources :invoices do
    member do
      post :finalize
      get :pdf
    end
    resources :line_items, controller: "invoice_line_items", only: [ :create, :update, :destroy ] do
      member do
        patch :reorder
      end
    end
  end
  resources :plugins, only: [:index] do
    member do
      patch :enable
      patch :disable
      post :sync
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#show"
end
