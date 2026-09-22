Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "jobs#index"

  get    "signup" => "registrations#new"
  post   "signup" => "registrations#create"
  get    "login"  => "sessions#new"
  post   "login"  => "sessions#create"
  delete "logout" => "sessions#destroy"

  resources :jobs, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]

  get "dashboard" => "dashboards#show"
end
