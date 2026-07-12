import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "select"]

  filter() {
    const query = this.searchTarget.value.trim().toLowerCase()

    for (const option of this.selectTarget.options) {
      const matches = option.text.toLowerCase().includes(query)
      option.hidden = !option.selected && !matches
    }
  }
}
