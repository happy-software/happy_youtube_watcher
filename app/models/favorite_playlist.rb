class FavoritePlaylist < ApplicationRecord
  belongs_to :user
  belongs_to :tracked_playlist
end
