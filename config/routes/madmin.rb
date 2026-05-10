# Below are the routes for madmin
namespace :madmin do
  resources :races
  resources :invites
  resources :groups
  resources :match_players
  resources :matches
  resources :players
  resources :leagues do
    post :start_season, on: :member
  end
  resources :maps
  resources :games
  resources :sessions
  resources :users
  root to: "dashboard#show"
end
