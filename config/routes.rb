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

  resources :failed_books, only: [ :index, :destroy ] do
    member do
      get :download
    end

    collection do
      delete :clear_all
    end
  end

  # Public libraries
  get "libraries", to: "libraries#index"
  get "libraries/:user_id", to: "libraries#show", as: "library"
  # Browsing a public library is the ordinary browse pages scoped to its owner,
  # see LibraryScoped.
  get "libraries/:user_id/books", to: "books#index", as: "library_books"
  get "libraries/:user_id/series", to: "series#index", as: "library_series"
  get "libraries/:user_id/authors", to: "authors#index", as: "library_authors"
  get "libraries/:user_id/series/:id", to: "series#show", as: "library_serie"
  get "libraries/:user_id/authors/:id", to: "authors#show", as: "library_author"

  resources :books, only: [ :index, :edit, :update, :destroy ] do
    collection do
      post :upload
    end

    member do
      get :download
      get :cover
    end
  end

  resources :series, only: [ :index, :show, :edit, :update ] do
    collection do
      get :download_all
    end

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
  root "series#index"
end
