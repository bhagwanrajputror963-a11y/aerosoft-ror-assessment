import { Controller } from "@hotwired/stimulus"

// Auto-submits the job search form as the user types, once a field has at
// least MIN_CHARS characters (debounced so it doesn't fire on every single
// keystroke), and immediately re-submits when a field is cleared back to
// empty so the full unfiltered list comes back without a manual click.
export default class extends Controller {
  static values = { minChars: { type: Number, default: 3 }, debounceMs: { type: Number, default: 400 } }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  search(event) {
    const length = event.target.value.trim().length

    if (length !== 0 && length < this.minCharsValue) return

    if (this.timeout) clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.debounceMsValue)
  }
}
