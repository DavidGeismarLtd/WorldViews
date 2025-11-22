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
    
    // For now, show a coming soon message
    // In the future, we could use html2canvas or similar library
    this.showNotification('📸 Screenshot feature coming soon!')
    
    // TODO: Implement screenshot functionality
    // This would require adding html2canvas or similar library
    // Example implementation:
    // const element = document.querySelector('.max-w-4xl')
    // const canvas = await html2canvas(element)
    // const dataUrl = canvas.toDataURL('image/png')
    // const link = document.createElement('a')
    // link.download = 'worldviews-reality-check.png'
    // link.href = dataUrl
    // link.click()
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

