import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { text: String }

  connect() {
    this.tooltip = document.createElement("div");
    this.tooltip.className = "tooltip-popup";
    this.tooltip.textContent = this.textValue;

    document.getElementsByClassName("playlists-page")[0].appendChild(this.tooltip);

    this.boundOutsideClick = this.handleOutsideClick.bind(this);
    document.addEventListener("click", this.boundOutsideClick);
  }

  show(event) {
    const rect = this.element.getBoundingClientRect();
    this.tooltip.style.top = `${rect.top - 8 + window.scrollY}px`;
    this.tooltip.style.left = `${rect.left + rect.width / 2}px`;
    this.tooltip.classList.add("visible");
  }

  hide() {
    this.tooltip.classList.remove("visible");
  }

  toggle(event) {
    event.preventDefault();
    event.stopPropagation();

    this.tooltip.classList.contains("visible") ? this.hide() : this.show();
  }

  handleOutsideClick(event) {
    if(!this.element.contains(event.target)) {
      this.hide();
    }
  }

  disconnect() {
    this.tooltip.remove();
    document.removeEventListener("click", this.boundOutsideClick);
  }
}
