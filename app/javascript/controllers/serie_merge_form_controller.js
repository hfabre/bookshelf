import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectedCount", "submitButton"]

  connect() {
    this.updateUI()
  }

  toggleSelection() {
    this.updateUI()
  }

  updateUI() {
    const selectedCount = this.checkboxTargets.filter(checkbox => checkbox.checked).length

    this.selectedCountTarget.textContent = selectedCount
    this.submitButtonTarget.disabled = selectedCount === 0
  }
}
