Rails.application.routes.draw do
  draw :madmin
  resource :session
  resource :registration
  resources :passwords, param: :token
  
  # Public league routes
  resources :leagues
  get "/invites/:token", to: "leagues#invite", as: :invite
  post "/leagues/:id/signup", to: "leagues#signup", as: :league_signup
  
  # User dashboard
  get "/dashboard", to: "dashboard#index", as: :dashboard
  
  # Match routes
  resources :matches, only: [:show, :index]
  post "/match_players/:id/ready", to: "match_players#ready", as: :match_player_ready
  post "/match_players/:id/race", to: "match_players#pick_race", as: :match_player_race
  post "/matches/:id/map", to: "matches#pick_map", as: :match_pick_map
  post "/matches/:id/result", to: "matches#report_result", as: :match_report_result
  post "/matches/:id/confirm", to: "matches#confirm_result", as: :match_confirm_result
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "leagues#index"
end
