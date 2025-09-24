import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeOnResize = this.closeOnResize.bind(this);
    window.addEventListener("resize", this.closeOnResize);
  }

  disconnect() {
    window.removeEventListener("resize", this.closeOnResize);
  }

  toggle() {
    this.menuTarget.classList.toggle("open");
  }

  closeOnResize() {
    if (window.innerWidth > 768) {
      this.menuTarget.classList.remove("open");
    }
  }
}
