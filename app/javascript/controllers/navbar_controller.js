import { Controller } from "@hotwired/stimulus"

// Handles the public navbar hamburger menu on mobile.
// The controller lives on <nav> itself; the sibling overlay element
// is wired up manually in connect() to avoid wrapping the sticky nav.
export default class extends Controller {
  static targets = ["links", "button"]

  connect() {
    this._overlay = document.getElementById("navbarMobileOverlay")
    this._onOverlayClick = () => this.close()
    this._overlay?.addEventListener("click", this._onOverlayClick)
  }

  disconnect() {
    this._overlay?.removeEventListener("click", this._onOverlayClick)
    this.close()
  }

  toggle(event) {
    event.stopPropagation()
    const isOpen = this.linksTarget.classList.toggle("open")
    this._overlay?.classList.toggle("open", isOpen)
    this.buttonTarget.setAttribute("aria-expanded", isOpen ? "true" : "false")
    document.body.classList.toggle("navbar-menu-open", isOpen)
  }

  close() {
    this.linksTarget.classList.remove("open")
    this._overlay?.classList.remove("open")
    this.buttonTarget?.setAttribute("aria-expanded", "false")
    document.body.classList.remove("navbar-menu-open")
  }

  // data-action="click@window->navbar#closeOnOutside"
  closeOnOutside(event) {
    if (!this.linksTarget.classList.contains("open")) return
    if (this.element.contains(event.target)) return
    this.close()
  }

  // data-action="resize@window->navbar#handleResize"
  handleResize() {
    if (window.innerWidth > 768) this.close()
  }
}
