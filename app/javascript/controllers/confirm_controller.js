import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { favoritePlaylistId: String, trackedPlaylistId: String }

  askRemoveFavoritePlaylist(event) {
    if (confirm("Are you sure you want to remove this playlist?")) {
      ahoy.track("remove_favorite_playlist_confirmed", { favorite_playlist_id: this.favoritePlaylistIdValue, tracked_playlist_id: this.trackedPlaylistIdValue });
    } else {
      ahoy.track("remove_favorite_playlist_cancelled", { favorite_playlist_id: this.favoritePlaylistIdValue, tracked_playlist_id: this.trackedPlaylistIdValue });
      event.preventDefault();
    }
  }
}
