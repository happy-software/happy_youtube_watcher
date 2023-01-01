import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log(`Connected to player_controller.js from ${this.element}`)
    const container = document.getElementById('container')
    const url = 'https://www.youtube.com/watch?v=d46Azg3Pm4c'

    renderReactPlayer(container, { url, playing: true })
  }

  pausePlayer () {
    renderReactPlayer(container, {url, playing: false})
  }
}
