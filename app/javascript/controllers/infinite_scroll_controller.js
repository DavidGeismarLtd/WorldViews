import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="infinite-scroll"
export default class extends Controller {
  static targets = ["entries", "pagination"]
  static values = {
    url: String
  }

  connect() {
    this.scroll = this.scroll.bind(this)
    this.observer = new IntersectionObserver(
      entries => this.handleIntersect(entries),
      {
        threshold: 0.1,
        rootMargin: "100px"
      }
    )

    if (this.hasPaginationTarget) {
      this.observer.observe(this.paginationTarget)
    }
  }

  disconnect() {
    this.observer.disconnect()
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.loadMore()
      }
    })
  }

  loadMore() {
    const nextLink = this.paginationTarget.querySelector('a[rel="next"]')

    if (!nextLink) {
      return
    }

    // Prevent multiple simultaneous requests
    if (this.loading) {
      return
    }

    this.loading = true

    // Fetch the next page with Turbo Stream
    fetch(nextLink.href, {
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => {
        // Let Turbo process the stream response
        Turbo.renderStreamMessage(html)
        this.loading = false
      })
      .catch(error => {
        console.error("Error loading more stories:", error)
        this.loading = false
      })
  }

  scroll() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.page()
    }, 200)
  }
}
