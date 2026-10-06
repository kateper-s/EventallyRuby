Rails.application.routes.draw do
  devise_for :users

  resources :events, only: %i[new create show] do
    resources :orders, only: :create
  end
  resources :demo_events, only: :show, path: "demo-events" do
    resources :orders, only: :create
  end
  get "my/events", to: "my_events#index", as: :my_events
  get "my/tickets", to: "my_tickets#index", as: :my_tickets

  root "home#index"
end
