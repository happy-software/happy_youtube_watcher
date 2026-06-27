import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { playlistId: String }

  askRemoveFavoritePlaylist(event) {
    if (confirm("Are you sure you want to remove this playlist?")) {
      ahoy.track("remove_favorite_playlist_confirmed", { playlist_id: this.playlistIdValue });
    } else {
      ahoy.track("remove_favorite_playlist_cancelled", { playlist_id: this.playlistIdValue });
      event.preventDefault();
    }
  }
}
