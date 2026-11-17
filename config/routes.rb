Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resource :session, only: %i[ new create destroy ]
  resource :registration, only: %i[ new create edit update destroy ]
  resources :passwords, param: :token, only: %i[ new create edit update ]

  resources :user_credentials
  resources :repositories do
    resources :collaborators, only: %i[create destroy]
  end

  # Asked by script/ssh-command-proxy.sh on every SSH connection.
  namespace :internal do
    resource :ssh_access, only: :create, controller: "ssh_access"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "user_credentials#index"
end
