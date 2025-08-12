# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "home#index"

  namespace :api do
    resources :books, only: [:index, :create, :update]
    get :soap, to: "soap#index"
  end
end
