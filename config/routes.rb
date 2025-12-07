Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session
  resources :passwords, param: :token
  get "profile/edit", to: "profiles#edit", as: "edit_profile"
  patch "profile", to: "profiles#update", as: "profile"

  resources :users, except: [ :show ]

  # Public libraries
  get "libraries", to: "libraries#index"
  get "libraries/:user_id", to: "libraries#show", as: "library"
  get "libraries/:user_id/books", to: "libraries#books", as: "library_books"
  get "libraries/:user_id/series", to: "libraries#series", as: "library_series"
  get "libraries/:user_id/authors", to: "libraries#authors", as: "library_authors"
  get "libraries/:user_id/series/:serie_id", to: "libraries#show_serie", as: "library_serie"
  get "libraries/:user_id/authors/:author_id", to: "libraries#show_author", as: "library_author"

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
      get :merge
      post :perform_merge, path: :merge
    end
  end

  resources :authors, only: [ :index, :show, :edit, :update ] do
    member do
      get :download
      get :merge
      post :perform_merge, path: :merge
    end
  end

  # Defines the root path route ("/")
  root "books#index"
end
