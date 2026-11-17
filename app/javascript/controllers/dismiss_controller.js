import { Controller } from "@hotwired/stimulus"

// Takes its element off the page: the "x" of a message.
export default class extends Controller {
  remove() {
    this.element.remove()
  }
}
