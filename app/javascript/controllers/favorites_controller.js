import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "output"]

  connect() {
    this.updateCSV()
  }

  toggleCheckbox() {
    this.updateCSV()
  }

  updateCSV() {
    const checkedBoxes = this.checkboxTargets.filter(checkbox => checkbox.checked)
    const playlistIds = checkedBoxes.map(checkbox => checkbox.value).filter(id => id)
    const csv = playlistIds.join(",")
    
    if (this.hasOutputTarget) {
      this.outputTarget.value = csv
    }
  }

  selectAll() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
    this.updateCSV()
  }

  deselectAll() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    this.updateCSV()
  }
}
