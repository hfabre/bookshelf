import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="author-merge-form"
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

    // Update selected count display
    this.selectedCountTarget.textContent = selectedCount

    // Update submit button state and text
    this.submitButtonTarget.disabled = selectedCount === 0

    if (selectedCount > 0) {
      this.submitButtonTarget.textContent = `Merge ${selectedCount} Author${selectedCount !== 1 ? 's' : ''}`
    } else {
      this.submitButtonTarget.textContent = 'Merge Selected Authors'
    }
  }
}


