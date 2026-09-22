Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "jobs#index"

  get    "signup" => "registrations#new"
  post   "signup" => "registrations#create"
  get    "login"  => "sessions#new"
  post   "login"  => "sessions#create"
  delete "logout" => "sessions#destroy"

  resources :jobs, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    resources :applications, only: [ :new, :create ]
  end

  resources :applications, only: [] do
    member do
      patch :update_status
    end
  end

  get "dashboard" => "dashboards#show"

  namespace :api do
    namespace :v1 do
      resources :jobs, only: [ :index, :show ]
      resources :applications, only: [ :create ]
    end
  end
end
