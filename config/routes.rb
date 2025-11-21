Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :books, only: [ :index, :edit, :update, :destroy ] do
    collection do
      post :upload
    end

    member do
      get :download
    end
  end

  resources :series, only: [ :index, :show, :edit, :update ] do
    member do
      get :download
    end
  end

  resources :authors, only: [ :index, :show, :edit, :update ] do
    member do
      get :download
    end
  end

  # Defines the root path route ("/")
  root "books#index"
end
