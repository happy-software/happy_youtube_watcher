import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "timeline", "loading"];

  initialize() {
    this.loading = false;
  }

  loadMore(event) {
    event.preventDefault();

    if (this.loading) return;

    this.loading = true;
    this.loadingTarget.style.display = "block"; // Show loading indicator

    const url = this.buttonTarget.getAttribute("href");

    if (url) {
      fetch(url, { headers: { "X-Requested-With": "XMLHttpRequest" } })
          .then(response => response.text())
          .then(html => {
            this.buttonTarget.remove(); // Remove the old "Load More" button from the page
            this.timelineTarget.insertAdjacentHTML("beforeend", html); // Append new items
            // this.updateButtonUrl();
          })
          .catch(error => console.error("Error loading more items:", error))
          .finally(() => {
            this.loading = false;
            this.loadingTarget.style.display = "none"; // Hide loading indicator
          });
    }
  }
}
