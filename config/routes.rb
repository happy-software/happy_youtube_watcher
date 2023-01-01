require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount Sidekiq::Web => '/sidekiq'

  post '/shuffle',           to: 'playlists#shuffle'
  get '/tracked-playlists',  to: 'tracked_playlists#index'
  post '/tracked-playlists', to: 'tracked_playlists#create'
  post '/playlist-settings', to: 'playlist_settings#create'

  get '/videos',             to: 'videos#index'

  get '/history',              to: 'playlist_history#index'
  get '/history/:playlist_id', to: 'playlist_history#show', as: :playlist_history
  get '/load_more_history/:playlist_id', to: 'playlist_history#load_more_history', as: :load_more_history

  # TODO: All the routes above this line should get refactored out at some point. We'll want all of the functionality
  #   built into SYT to get moved over to HYTW and then sunset SYT.

  resources :favorite_playlists
  get '/player', to: 'player#index'
end
