Rails.application.routes.draw do
  namespace :api do
    resources :users, only: %i[create]
  end

  resources :users, only: %i[index]

  get 'health', to: 'health#show'

  root 'users#index'
end
