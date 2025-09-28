import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.isSelecting = false;
  }

  startSelect(event) {
    this.isSelecting = true;
    this.toggleItem(event.target);
  }

  moveSelect(event) {
    if (!this.isSelecting) return;

    const touch = event.touches[0];
    const element = document.elementFromPoint(touch.clientX, touch.clientY);

    if (element && element.closest(".playlist-item")) {
      this.toggleItem(element.closest(".playlist-item"));
    }
  }

  endSelect() {
    this.isSelecting = false;
  }

  toggleItem(item) {
    if (!item.classList.contains("playlist-item")) return;

    const checkbox = item.querySelector(".playlist-checkbox");
    item.querySelector(".playlist-checkbox").checked = true;

    // Manually trigger a change event so favorites_controller's savePlaylistSelectionLocally method gets kicked off
    checkbox.dispatchEvent(new Event("change", { bubbles: true}));
  }
}
