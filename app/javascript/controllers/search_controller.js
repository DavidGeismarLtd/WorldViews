import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "loader", "results"]
  static values = {
    delay: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  search() {
    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Show loader
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.remove("hidden")
    }

    // Debounce the search
    this.timeout = setTimeout(() => {
      this.submitSearch()
    }, this.delayValue)
  }

  submitSearch() {
    // Submit the form (Turbo will handle the request)
    this.formTarget.requestSubmit()
  }

  hideLoader() {
    // Hide loader after turbo frame loads
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.add("hidden")
    }
  }
}

