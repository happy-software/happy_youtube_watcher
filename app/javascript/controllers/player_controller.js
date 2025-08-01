import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log(`Connected to player_controller.js from ${this.element}`)
    const container = document.getElementById('container')
    const urls = ["https://www.youtube.com/watch?v=5h_hnvfStsE", "https://www.youtube.com/watch?v=S8YsF-sBf0Q"]
    renderReactPlayer(container, {
      url: urls,
      playing: true,
      controls: true
    })
  }
}
