import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 0 } }

  connect() {
    if (this.timeoutValue > 0) {
      this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    clearTimeout(this.timer)
    this.element.style.transition = "opacity 200ms ease, transform 200ms ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-4px)"
    setTimeout(() => this.element.remove(), 200)
  }
}
