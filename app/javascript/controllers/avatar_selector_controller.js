import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="avatar-selector"
export default class extends Controller {
  static targets = [
    "option",
    "uploadSection",
    "linkSection",
    "letterSection",
    "aiSection",
    "preview",
    "avatarUrlField",
    "avatarTypeField",
    "fileInput"
  ]

  connect() {
    // Set initial state based on existing avatar_url or default to AI
    this.updateSelection()
  }

  selectOption(event) {
    const selectedOption = event.currentTarget.dataset.avatarOption

    // Update UI - highlight selected option
    this.optionTargets.forEach(option => {
      if (option.dataset.avatarOption === selectedOption) {
        option.classList.add("ring-2", "ring-purple-500", "bg-purple-50")
        option.classList.remove("bg-white")
      } else {
        option.classList.remove("ring-2", "ring-purple-500", "bg-purple-50")
        option.classList.add("bg-white")
      }
    })

    // Show/hide relevant sections
    this.hideAllSections()
    
    switch(selectedOption) {
      case "upload":
        this.uploadSectionTarget.classList.remove("hidden")
        this.avatarTypeFieldTarget.value = "upload"
        break
      case "link":
        this.linkSectionTarget.classList.remove("hidden")
        this.avatarTypeFieldTarget.value = "link"
        break
      case "letter":
        this.letterSectionTarget.classList.remove("hidden")
        this.avatarTypeFieldTarget.value = "letter"
        this.avatarUrlFieldTarget.value = "" // Clear avatar_url for letter option
        this.updatePreview()
        break
      case "ai":
        this.aiSectionTarget.classList.remove("hidden")
        this.avatarTypeFieldTarget.value = "ai"
        this.avatarUrlFieldTarget.value = "" // Clear avatar_url to trigger AI generation
        this.updatePreview()
        break
    }
  }

  hideAllSections() {
    this.uploadSectionTarget.classList.add("hidden")
    this.linkSectionTarget.classList.add("hidden")
    this.letterSectionTarget.classList.add("hidden")
    this.aiSectionTarget.classList.add("hidden")
  }

  updateSelection() {
    // Determine which option should be selected based on current state
    const avatarUrl = this.avatarUrlFieldTarget.value
    const avatarType = this.avatarTypeFieldTarget.value

    let selectedOption = avatarType || "ai" // Default to AI

    if (avatarUrl && avatarUrl.trim() !== "") {
      selectedOption = "link"
    }

    // Trigger selection
    const optionElement = this.optionTargets.find(
      option => option.dataset.avatarOption === selectedOption
    )
    
    if (optionElement) {
      optionElement.click()
    }
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (file) {
      // For now, we'll just show a preview
      // In production, you'd upload to cloud storage (S3, Cloudinary, etc.)
      const reader = new FileReader()
      reader.onload = (e) => {
        this.showPreview(e.target.result)
        // Store the data URL temporarily (in production, upload to cloud)
        this.avatarUrlFieldTarget.value = e.target.result
      }
      reader.readAsDataURL(file)
    }
  }

  handleLinkInput(event) {
    const url = event.target.value
    this.avatarUrlFieldTarget.value = url
    if (url && url.trim() !== "") {
      this.showPreview(url)
    }
  }

  showPreview(imageUrl) {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <img src="${imageUrl}" alt="Avatar preview" class="w-full h-full object-cover rounded-full">
      `
    }
  }

  updatePreview() {
    if (this.hasPreviewTarget) {
      const avatarType = this.avatarTypeFieldTarget.value
      const nameField = document.querySelector('input[name="persona[name]"]')
      const name = nameField ? nameField.value : ""
      const firstLetter = name ? name[0].toUpperCase() : "?"

      if (avatarType === "letter") {
        this.previewTarget.innerHTML = `
          <div class="w-full h-full rounded-full bg-purple-600 flex items-center justify-center text-white text-4xl font-bold">
            ${firstLetter}
          </div>
        `
      } else if (avatarType === "ai") {
        this.previewTarget.innerHTML = `
          <div class="w-full h-full rounded-full bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center text-white">
            <div class="text-center">
              <div class="text-3xl mb-1">🎨</div>
              <div class="text-xs font-semibold">AI Generated</div>
            </div>
          </div>
        `
      }
    }
  }
}

