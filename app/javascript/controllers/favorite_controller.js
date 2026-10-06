import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, loginUrl: String, active: Boolean }

  activeValueChanged(active) {
    this.element.setAttribute("aria-pressed", String(active))
    this.element.setAttribute("aria-label", active ? "Убрать из избранного" : "Добавить в избранное")
  }

  async toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    if (this.busy) return

    const active = !this.activeValue
    this.activeValue = active
    this.element.animate(
      [{ transform: "scale(1)" }, { transform: "scale(1.25)" }, { transform: "scale(1)" }],
      { duration: 250, easing: "ease-out" }
    )

    this.busy = true
    try {
      const response = await fetch(this.urlValue, {
        method: active ? "POST" : "DELETE",
        headers: { "X-CSRF-Token": this.#csrfToken, Accept: "application/json" },
        credentials: "same-origin"
      })

      if (response.status === 401) {
        this.activeValue = !active
        window.Turbo ? window.Turbo.visit(this.loginUrlValue) : (window.location.href = this.loginUrlValue)
        return
      }
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      this.dispatch("changed", { detail: { active } })
    } catch {
      this.activeValue = !active
    } finally {
      this.busy = false
    }
  }

  get #csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
