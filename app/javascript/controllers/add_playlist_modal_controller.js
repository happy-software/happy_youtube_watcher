import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];
  static values = { hasErrors: Boolean, errors: Array };

  connect() {
    if (this.hasErrorsValue) {
      ahoy.track("add_playlist_modal_opened_with_errors", { errors: this.errorsValue });
      this.showModal();
    }
  }

  open() {
    ahoy.track("add_playlist_modal_opened");
    this.showModal();
  }

  close(event) {
    // TODO: Need to figure out how to make the modal go away when clicking outside the modal for a better UX
    // if (event && event.target.closest(".modal-content")) return // don't close when clicking inside
    ahoy.track("add_playlist_modal_closed");
    this.containerTarget.classList.add("hidden");
    document.body.style.overflow = "";
  }

  showModal() {
    this.containerTarget.classList.remove("hidden");
    document.body.style.overflow = "hidden"; // prevent background scroll
  }
}
