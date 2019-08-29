Rails.application.routes.draw do

  namespace :api do
    namespace :v1 do
      resources :subscriptions
      post '/add_sub', to: 'subscriptions#add_sub'
      post '/charge_sub', to: 'subscriptions#charge_sub'
      get '/cancel_sub', to: 'subscriptions#cancel_sub'
    end
  end

  resources :subscriptions
end
