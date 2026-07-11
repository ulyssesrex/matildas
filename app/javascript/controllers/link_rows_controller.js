import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "rows"]

  add() {
    const key = `${Date.now()}-${Math.random().toString(16).slice(2)}`
    const row = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", key)
    this.rowsTarget.insertAdjacentHTML("beforeend", row)
  }

  remove(event) {
    event.currentTarget.closest("[data-link-row]").remove()
  }
}
