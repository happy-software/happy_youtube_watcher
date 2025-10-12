require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  namespace :admin do
    get "dashboard/index"
  end
  devise_for :users

  # Admin namespace
  authenticate :user, -> (u) { u.is_admin? } do
    namespace :admin do
      mount Sidekiq::Web => '/sidekiq'
      get '/', to: 'dashboard#index'
    end
  end

  post '/shuffle',           to: 'playlists#shuffle'
  get '/tracked-playlists',  to: 'tracked_playlists#index'
  post '/tracked-playlists', to: 'tracked_playlists#create'
  post '/playlist-settings', to: 'playlist_settings#create'

  get '/videos',             to: 'videos#index'

  # TODO: All the routes above this line should get refactored out at some point. We'll want all of the functionality
  #   built into SYT to get moved over to HYTW and then sunset SYT.

  # Static Pages
  get "home", to: "pages#home"

  get '/history',              to: 'playlist_history#index'
  get '/history/:playlist_id', to: 'playlist_history#show', as: :playlist_history
  get '/load_more_history/:playlist_id', to: 'playlist_history#load_more_history', as: :load_more_history

  resources :favorite_playlists, path: 'favorites'
  get '/create-mix', to: 'favorite_playlists/mixes#index', as: :create_mix
  get '/player', to: 'player#index'

  # UserFeedback
  get "submit-feedback",  to: "user_feedbacks#new",    as: :new_feedback
  post "submit-feedback", to: "user_feedbacks#create", as: :feedback

  root to: 'pages#home'
end
