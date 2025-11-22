import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="persona-carousel"
export default class extends Controller {
  static targets = ["card", "tab", "container"]

  connect() {
    this.currentIndex = 0
    this.totalCards = this.cardTargets.length
    
    // Add touch/swipe support
    this.setupSwipeGestures()
    
    // Add keyboard navigation
    this.setupKeyboardNavigation()
  }

  selectPersona(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.showCard(index)
  }

  next() {
    const nextIndex = (this.currentIndex + 1) % this.totalCards
    this.showCard(nextIndex)
  }

  previous() {
    const prevIndex = (this.currentIndex - 1 + this.totalCards) % this.totalCards
    this.showCard(prevIndex)
  }

  showCard(index) {
    // Hide all cards
    this.cardTargets.forEach((card, i) => {
      if (i === index) {
        card.classList.remove('hidden')
        card.classList.add('animate-fade-in')
      } else {
        card.classList.add('hidden')
        card.classList.remove('animate-fade-in')
      }
    })

    // Update tabs
    this.tabTargets.forEach((tab, i) => {
      const persona = this.getPersonaData(i)
      
      if (i === index) {
        tab.classList.remove('bg-white', 'text-gray-700', 'hover:bg-gray-100')
        tab.classList.add('text-white')
        tab.style.backgroundColor = persona.color
      } else {
        tab.classList.add('bg-white', 'text-gray-700', 'hover:bg-gray-100')
        tab.classList.remove('text-white')
        tab.style.backgroundColor = ''
      }
    })

    this.currentIndex = index

    // Scroll tab into view
    this.tabTargets[index].scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' })
  }

  setupSwipeGestures() {
    let touchStartX = 0
    let touchEndX = 0

    this.containerTarget.addEventListener('touchstart', (e) => {
      touchStartX = e.changedTouches[0].screenX
    }, { passive: true })

    this.containerTarget.addEventListener('touchend', (e) => {
      touchEndX = e.changedTouches[0].screenX
      this.handleSwipe(touchStartX, touchEndX)
    }, { passive: true })
  }

  handleSwipe(startX, endX) {
    const swipeThreshold = 50
    const diff = startX - endX

    if (Math.abs(diff) > swipeThreshold) {
      if (diff > 0) {
        // Swiped left - show next
        this.next()
      } else {
        // Swiped right - show previous
        this.previous()
      }
    }
  }

  setupKeyboardNavigation() {
    document.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft') {
        this.previous()
      } else if (e.key === 'ArrowRight') {
        this.next()
      }
    })
  }

  getPersonaData(index) {
    const tab = this.tabTargets[index]
    const card = this.cardTargets[index]
    
    // Extract color from the card's border
    const borderColor = card.querySelector('[style*="border-color"]')?.style.borderColor || '#6B7280'
    
    return {
      color: borderColor
    }
  }
}

