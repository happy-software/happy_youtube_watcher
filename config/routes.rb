Rails.application.routes.draw do
  get '/player/:playlist_ids', to: 'player#index', constraints: { playlist_ids: /\d+(?:,\d+)*/ }
end
