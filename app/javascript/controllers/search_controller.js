import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["input", "loading"]
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)

    this.timeout = setTimeout(() => {
      this.performSearch()
    }, this.delayValue)
  }

  performSearch() {
    const query = this.inputTarget.value.trim()

    // Only search if query has at least 2 characters or is empty (to show all)
    if (query.length >= 2 || query.length === 0) {
      this.element.requestSubmit()
    }
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
