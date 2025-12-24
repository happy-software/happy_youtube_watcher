import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"];

  connect() {
    this.savePlaylistSelectionLocally = this.savePlaylistSelectionLocally.bind(this);
    this.element.addEventListener('change', this.savePlaylistSelectionLocally);

    this.setPreviouslySelectedPlaylists();
  }

  disconnect() {
    this.element.removeEventListener('change', this.savePlaylistSelectionLocally);
  }

  savePlaylistSelectionLocally() {
    const checkboxes = Array.from(this.element.querySelectorAll("input[type='checkbox']"));
    const selectedPlaylists = checkboxes.filter(cb => cb.checked).map(cb => cb.value);
    localStorage.setItem("playlistSelection", selectedPlaylists);
  }

  setPreviouslySelectedPlaylists() {
    let previouslySelectedPlaylists = (localStorage.getItem("playlistSelection") || '').split(",");

    if (previouslySelectedPlaylists.length > 0) {
      const checkboxes = Array.from(this.element.querySelectorAll("input[type='checkbox']"));
      checkboxes.filter(cb => previouslySelectedPlaylists.includes(cb.value)).forEach(cb => cb.checked = true);
    }
  }

  filterList(event) {
    const query = event.target.value.toLowerCase();
    const items = this.listTarget.querySelectorAll(".playlist-card")

    ahoy.track("filter_favorites_playlist", { query: query });

    items.forEach(item => {
      const name = item.dataset.name.toLowerCase();
      const playlistId = item.dataset.playlistId.toLowerCase();
      const matches = name.includes(query) || playlistId.includes(query)
      item.style.display = matches ? "" : "none";
    })
  }
}
