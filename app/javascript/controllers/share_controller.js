import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share"
export default class extends Controller {
  static values = {
    url: String,
    title: String,
    text: String
  }

  // Share using Web Share API (mobile-friendly) with fallback
  async share(event) {
    event.preventDefault()

    const shareData = {
      title: this.titleValue || document.title,
      text: this.textValue || '',
      url: this.urlValue || window.location.href
    }

    // Check if Web Share API is supported (mainly mobile browsers)
    if (navigator.share) {
      try {
        await navigator.share(shareData)
      } catch (err) {
        // User cancelled or error occurred
        if (err.name !== 'AbortError') {
          console.error('Error sharing:', err)
          this.fallbackShare()
        }
      }
    } else {
      // Fallback for desktop browsers
      this.fallbackShare()
    }
  }

  // Fallback share method - copy link to clipboard
  fallbackShare() {
    const url = this.urlValue || window.location.href

    navigator.clipboard.writeText(url).then(() => {
      // Show success message
      this.showNotification('Link copied to clipboard! 📋')
    }).catch(err => {
      console.error('Failed to copy:', err)
      this.showNotification('Failed to copy link ❌')
    })
  }

  // Screenshot functionality
  async screenshot(event) {
    event.preventDefault()

    // Check if html2canvas is available
    if (typeof window.html2canvas === 'undefined') {
      this.showNotification('❌ Screenshot library not loaded')
      return
    }

    try {
      this.showNotification('📸 Capturing screenshot...')

      // Find the main content area to screenshot
      const element = document.querySelector('.max-w-4xl')

      if (!element) {
        this.showNotification('❌ Could not find content to screenshot')
        return
      }

      // Capture the screenshot using global html2canvas
      const canvas = await window.html2canvas(element, {
        backgroundColor: '#f9fafb',
        scale: 2, // Higher quality
        logging: false,
        useCORS: true, // Allow cross-origin images
        allowTaint: true
      })

      // Convert to blob and download
      canvas.toBlob((blob) => {
        const url = URL.createObjectURL(blob)
        const link = document.createElement('a')
        const timestamp = new Date().toISOString().slice(0, 10)
        link.download = `worldviews-${timestamp}.png`
        link.href = url
        link.click()
        URL.revokeObjectURL(url)
        this.showNotification('✅ Screenshot saved!')
      }, 'image/png')

    } catch (error) {
      console.error('Screenshot error:', error)
      this.showNotification('❌ Failed to capture screenshot')
    }
  }

  // Show a temporary notification
  showNotification(message) {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = 'fixed top-20 left-1/2 transform -translate-x-1/2 bg-gray-900 text-white px-6 py-3 rounded-full shadow-lg z-50 transition-all duration-300'
    notification.textContent = message
    notification.style.opacity = '0'

    document.body.appendChild(notification)

    // Fade in
    setTimeout(() => {
      notification.style.opacity = '1'
    }, 10)

    // Fade out and remove
    setTimeout(() => {
      notification.style.opacity = '0'
      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 2500)
  }
}
