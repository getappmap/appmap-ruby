Rails.application.routes.draw do
  resources :users, only: %i[create]

  get 'health', to: 'health#show'
end
