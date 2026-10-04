import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "search", "clear", "hotkey", "results"]
  static values = { debounce: { type: Number, default: 300 } }

  connect() {
    this.element.querySelectorAll("turbo-frame[busy]").forEach((frame) => {
      frame.removeAttribute("busy")
      frame.removeAttribute("aria-busy")
    })
    this.#applyParams(new URLSearchParams(window.location.search))
    this.#syncClearButton()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  submit() {
    clearTimeout(this.timer)
    this.formTarget.requestSubmit()
  }

  search() {
    this.#syncClearButton()
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.submit(), this.debounceValue)
  }

  submitAndScroll(event) {
    event.preventDefault()
    this.submit()
    if (this.hasResultsTarget) {
      this.resultsTarget.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }

  clearSearch() {
    if (!this.hasSearchTarget) return
    this.searchTarget.value = ""
    this.searchTarget.focus()
    this.#syncClearButton()
    this.submit()
  }

  reset(event) {
    event?.preventDefault()
    this.#applyParams(new URLSearchParams())
    this.#syncClearButton()
    this.submit()
  }

  focusSearch(event) {
    const tag = event.target.tagName
    if (event.key !== "/" || ["INPUT", "TEXTAREA", "SELECT"].includes(tag) || event.target.isContentEditable) return

    event.preventDefault()
    if (this.hasSearchTarget) this.searchTarget.focus()
  }

  searchKeydown(event) {
    if (event.key === "Escape" && this.searchTarget.value) {
      event.preventDefault()
      this.clearSearch()
    }
  }

  #applyParams(params) {
    const fields = Array.from(this.formTarget.elements).filter((field) => field.name)

    fields.forEach((field) => {
      const value = params.get(field.name) ?? ""

      if (field.type === "radio") {
        const group = fields.filter((f) => f.type === "radio" && f.name === field.name)
        const known = group.some((f) => f.value === value)
        field.checked = field.value === (known ? value : "")
      } else if (field.type === "checkbox") {
        field.checked = value === field.value
      } else if (field.tagName === "SELECT") {
        field.value = value
        if (field.selectedIndex === -1) field.selectedIndex = 0
      } else if (field.type === "search" || field.type === "text") {
        field.value = value
      }
    })
  }

  #syncClearButton() {
    if (!this.hasSearchTarget) return
    const empty = this.searchTarget.value.trim() === ""
    if (this.hasClearTarget) this.clearTarget.hidden = empty
    if (this.hasHotkeyTarget) this.hotkeyTarget.hidden = !empty
  }
}
