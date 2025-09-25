import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeOnResize = this.closeOnResize.bind(this);
    window.addEventListener("resize", this.closeOnResize);

    // Restore saved dark mode preference, if it exists
    const darkModeEnabled = localStorage.getItem("darkMode") === "true";
    if (darkModeEnabled) {
      document.body.classList.add("dark-mode");
      const toggle = document.getElementById("darkModeToggle");
      if (toggle) toggle.checked = true;
    }
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

  toggleDarkMode(event) {
    const enabled = event.target.checked;
    document.body.classList.toggle("dark-mode", enabled);
    localStorage.setItem("darkMode", enabled);
  }
}
