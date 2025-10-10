import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];

  open() {
    this.containerTarget.classList.remove("hidden");
    document.body.style.overflow = "hidden"; // prevent background scroll
  }

  close(event) {
    // TODO: Need to figure out how to make the modal go away when clicking outside the modal for a better UX
    // if (event && event.target.closest(".modal-content")) return // don't close when clicking inside
    this.containerTarget.classList.add("hidden");
    document.body.style.overflow = "";
  }
}
