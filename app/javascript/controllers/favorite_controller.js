import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "eventally:favorites"

export default class extends Controller {
  static values = { id: String }

  connect() {
    this.#render(this.#load().has(this.idValue))
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    const favorites = this.#load()
    const active = !favorites.has(this.idValue)
    active ? favorites.add(this.idValue) : favorites.delete(this.idValue)
    this.#save(favorites)
    this.#render(active)

    this.element.animate(
      [{ transform: "scale(1)" }, { transform: "scale(1.25)" }, { transform: "scale(1)" }],
      { duration: 250, easing: "ease-out" }
    )
  }

  #render(active) {
    this.element.setAttribute("aria-pressed", String(active))
    this.element.setAttribute("aria-label", active ? "Убрать из избранного" : "Добавить в избранное")
  }

  #load() {
    try {
      return new Set(JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]"))
    } catch {
      return new Set()
    }
  }

  #save(favorites) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify([...favorites]))
    } catch {
    }
  }
}
