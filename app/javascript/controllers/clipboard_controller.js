import { Controller } from "@hotwired/stimulus"

// Copies its text value to the clipboard and says so for a moment.
export default class extends Controller {
  static values = { text: String }
  static targets = [ "status" ]

  disconnect() {
    clearTimeout(this.timeout)
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
    } catch {
      // No clipboard for pages served without HTTPS: copy as a selection.
      if (!this.copyAsSelection()) return
    }

    this.element.classList.add("is-copied")
    this.statusTarget.textContent = "Copied"

    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.classList.remove("is-copied")
      this.statusTarget.textContent = ""
    }, 2000)
  }

  copyAsSelection() {
    const field = document.createElement("textarea")

    field.value = this.textValue
    field.setAttribute("readonly", "")
    field.style.cssText = "position: fixed; opacity: 0"
    document.body.append(field)
    field.select()

    try {
      return document.execCommand("copy")
    } finally {
      field.remove()
    }
  }
}
