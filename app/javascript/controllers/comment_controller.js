import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["delete"]
  static values = { author: String }

  connect() {
    const me = document.querySelector("meta[name='current-user-id']")?.content
    const organizer = this.element.closest("[data-organizer-id]")?.dataset.organizerId
    const allowed = Boolean(me) && (me === this.authorValue || me === organizer)
    this.deleteTargets.forEach((form) => { form.hidden = !allowed })
  }
}
