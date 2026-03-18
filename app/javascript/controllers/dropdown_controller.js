import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeHandler = (event) => {
      if (!this.element.contains(event.target)) {
        this.hide()
      }
    }

    document.addEventListener("click", this.closeHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.closeHandler)
  }

  toggle() {
    if (this.menuTarget.style.display === "block") {
      this.hide()
    } else {
      this.show()
    }
  }

  show() {
    this.menuTarget.style.display = "block"
  }

  hide() {
    this.menuTarget.style.display = "none"
  }
end