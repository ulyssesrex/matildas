import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "rows"]

  connect() {
    this.nextIndex = Date.now()
  }

  add() {
    const row = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", this.nextIndex++)
    this.rowsTarget.insertAdjacentHTML("beforeend", row)
  }

  remove(event) {
    event.currentTarget.closest("[data-artist-row]").remove()
  }
}
