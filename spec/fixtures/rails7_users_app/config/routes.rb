Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"

  namespace :api do
    resources :users, only: %i[index create]
  end

  resources :users, only: %i[index show]

  get 'health', to: 'health#show'

  root 'users#index'
end
