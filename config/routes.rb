Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root to: proc {
    body = { name: "E-commerce API", endpoints: %w[/auth/register /auth/login /auth/me /products /services /categories /carts /orders] }.to_json
    [200, { "Content-Type" => "application/json" }, [body]]
  }

  resources :categories

  resources :products do
    resources :variants, only: %i[index show create update destroy]
    resources :reviews, only: %i[index create destroy]
  end

  resources :services do
    resources :reviews, only: %i[index create destroy]
  end

  resources :carts, only: %i[index create show destroy] do
    resources :cart_items, only: %i[index show create update destroy]
    member do
      post :checkout
    end
  end

  resources :orders do
    resources :order_items, only: %i[index]
    member do
      post :cancel
    end
  end


  # Authentication
  namespace :auth do
    post "register", to: "registrations#create"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    get "me", to: "users#show"
    patch "me", to: "users#update"
    delete "me", to: "users#destroy"
  end

  get "/404" => "errors#not_found"

  # Swagger UI and the OpenAPI spec
  mount Rswag::Ui::Engine => "/swagger"
  mount Rswag::Api::Engine => "/api-docs"
end
