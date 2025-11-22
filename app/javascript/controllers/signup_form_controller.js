import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["password", "strengthBar", "strengthText", "eyeIcon", "toggleButton"]

  connect() {
    console.log("Signup form controller connected")
  }

  togglePassword(event) {
    event.preventDefault()
    const passwordField = this.passwordTarget
    const eyeIcon = this.eyeIconTarget

    if (passwordField.type === "password") {
      passwordField.type = "text"
      eyeIcon.textContent = "🙈" // Hide icon when password is visible
    } else {
      passwordField.type = "password"
      eyeIcon.textContent = "👁️" // Show icon when password is hidden
    }
  }

  checkPasswordStrength() {
    const password = this.passwordTarget.value
    const strength = this.calculateStrength(password)

    // Update the strength bar
    this.strengthBarTarget.style.width = `${strength.percentage}%`
    this.strengthBarTarget.style.backgroundColor = strength.color

    // Update the strength text
    if (password.length === 0) {
      this.strengthTextTarget.textContent = this.hasTarget("strengthText") &&
        this.strengthTextTarget.dataset.minLength ?
        `${this.strengthTextTarget.dataset.minLength} characters minimum` :
        "6 characters minimum"
    } else {
      this.strengthTextTarget.textContent = strength.text
      this.strengthTextTarget.style.color = strength.color
    }
  }

  calculateStrength(password) {
    let score = 0

    if (password.length === 0) {
      return { percentage: 0, color: "#e5e7eb", text: "" }
    }

    // Length check
    if (password.length >= 6) score += 20
    if (password.length >= 8) score += 10
    if (password.length >= 12) score += 10

    // Character variety checks
    if (/[a-z]/.test(password)) score += 15
    if (/[A-Z]/.test(password)) score += 15
    if (/[0-9]/.test(password)) score += 15
    if (/[^a-zA-Z0-9]/.test(password)) score += 15

    // Determine color and text based on score
    let color, text

    if (score < 30) {
      color = "#ef4444" // red
      text = "Weak password"
    } else if (score < 50) {
      color = "#f59e0b" // orange
      text = "Fair password"
    } else if (score < 70) {
      color = "#eab308" // yellow
      text = "Good password"
    } else {
      color = "#22c55e" // green
      text = "Strong password"
    }

    return {
      percentage: Math.min(score, 100),
      color: color,
      text: text
    }
  }
}
