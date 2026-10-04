import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  toggle(event) {
    event?.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (!this.hasMenuTarget) return
    this.menuTarget.hidden = false
    this.#setExpanded(true)
  }

  close() {
    if (!this.hasMenuTarget || this.menuTarget.hidden) return
    this.menuTarget.hidden = true
    this.#setExpanded(false)
  }

  closeOnClickOutside(event) {
    if (this.isOpen && !this.element.contains(event.target)) this.close()
  }

  get isOpen() {
    return this.hasMenuTarget && !this.menuTarget.hidden
  }

  #setExpanded(value) {
    this.buttonTargets.forEach((button) => button.setAttribute("aria-expanded", String(value)))
  }
}
