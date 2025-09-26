import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

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
}
