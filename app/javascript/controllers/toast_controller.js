import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toast"
export default class extends Controller {
  static values = {
    message: String,
    type: String, // success, error, info
    duration: { type: Number, default: 3000 }
  }

  connect() {
    this.show()
  }

  show() {
    const toast = this.element
    
    // Set colors based on type
    const colors = {
      success: 'bg-green-600',
      error: 'bg-red-600',
      info: 'bg-blue-600',
      default: 'bg-gray-900'
    }
    
    const color = colors[this.typeValue] || colors.default
    toast.classList.add(color)
    
    // Fade in
    setTimeout(() => {
      toast.classList.remove('opacity-0', 'translate-y-2')
      toast.classList.add('opacity-100', 'translate-y-0')
    }, 10)

    // Fade out and remove
    setTimeout(() => {
      this.hide()
    }, this.durationValue)
  }

  hide() {
    const toast = this.element
    toast.classList.remove('opacity-100', 'translate-y-0')
    toast.classList.add('opacity-0', 'translate-y-2')
    
    setTimeout(() => {
      toast.remove()
    }, 300)
  }

  // Allow manual dismissal
  dismiss() {
    this.hide()
  }
}

