// app/javascript/controllers/notifications_controller.js
// Gère le dropdown des notifications dans la topbar de l'espace entreprise.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "toggle"]

  connect() {
    // Ferme le dropdown au clic en dehors
    this.outsideClickHandler = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }

  toggle(event) {
    event.stopPropagation()
    const dropdown = this.dropdownTarget
    const isOpen = dropdown.style.display !== "none"
    dropdown.style.display = isOpen ? "none" : "block"
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      if (this.hasDropdownTarget) {
        this.dropdownTarget.style.display = "none"
      }
    }
  }
}
