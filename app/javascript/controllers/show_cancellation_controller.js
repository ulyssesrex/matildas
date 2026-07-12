import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "ordinaryNotes", "cancellationNotes"]

  connect() {
    this.toggle()
  }

  toggle() {
    const cancelled = this.checkboxTarget.checked
    this.ordinaryNotesTarget.hidden = cancelled
    this.cancellationNotesTarget.hidden = !cancelled
  }
}
