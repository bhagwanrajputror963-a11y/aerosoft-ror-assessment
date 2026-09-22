Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get    "signup" => "registrations#new"
  post   "signup" => "registrations#create"
  get    "login"  => "sessions#new"
  post   "login"  => "sessions#create"
  delete "logout" => "sessions#destroy"

  get "dashboard" => "dashboards#show"

  root "sessions#new"
end
