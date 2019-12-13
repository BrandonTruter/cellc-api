Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :subscriptions
      post '/charge', to: 'subscriptions#charge'
      post '/add_sub', to: 'subscriptions#add_sub'
      post '/charge_sub', to: 'subscriptions#charge_sub'
      post '/cancel_sub', to: 'subscriptions#cancel_sub'
      post '/notify_sub', to: 'subscriptions#notify_sub'
    end
  end
  # resources :subscriptions
end
