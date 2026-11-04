import { Controller } from "@hotwired/stimulus"

// Runs the search as you type and swaps in the results without reloading the page
export default class extends Controller {
  static targets = ["form", "results"];

  disconnect() {
    clearTimeout(this.timeout);
    this.abortController?.abort();
  }

  // Wait until typing pauses so we don't send a request for every keystroke
  queue() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => this.search(), 250);
  }

  submit(event) {
    event.preventDefault();
    this.search();
  }

  search() {
    clearTimeout(this.timeout);
    this.abortController?.abort(); // Drop any slower, older request so it can't overwrite newer results
    this.abortController = new AbortController();

    const params = new URLSearchParams(new FormData(this.formTarget));
    const url = `${this.formTarget.action}?${params}`;
    history.replaceState(null, "", url); // Keep the URL shareable and the results there after a refresh

    fetch(url, { headers: { "X-Requested-With": "XMLHttpRequest" }, signal: this.abortController.signal })
      .then(response => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return response.text();
      })
      .then(html => { this.resultsTarget.innerHTML = html; })
      .catch(error => {
        if (error.name === "AbortError") return;
        ahoy.track("search_failed", { url: url, error: error.message });
        console.error("Error searching:", error);
      });
  }
}
