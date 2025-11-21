import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "loading"]

  connect() {
    this.timeout = null
  }

  search() {
    // Clear any existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Debounce the search to avoid too many requests
    this.timeout = setTimeout(() => {
      this.performSearch()
    }, 300) // Wait 300ms after user stops typing
  }

  performSearch() {
    // Show loading state
    this.showLoading()

    // Submit the form which will trigger a Turbo Frame request
    this.element.requestSubmit()
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
  }
}
