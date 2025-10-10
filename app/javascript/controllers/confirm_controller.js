import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  askRemoveFavoritePlaylist(event) {
    if (!confirm("Are you sure you want to remove this playlist?")) {
      event.preventDefault();
    }
  }
}
