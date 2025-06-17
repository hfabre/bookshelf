import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput"]

  openFileDialog() {
    this.fileInputTarget.click()
  }

  handleFiles() {
    const files = this.fileInputTarget.files
    if (files.length > 0) {
      // Auto-submit the form when files are selected
      this.element.submit()
    }
  }
}
