import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "overlay", "panel"]

  connect() {
    this.close()
  }

  toggle() {
    const open = !this.panelTarget.classList.contains("open")
    this.panelTarget.classList.toggle("open", open)
    this.overlayTarget.classList.toggle("active", open)
    this.buttonTarget.setAttribute("aria-expanded", open ? "true" : "false")
  }

  close() {
    if (this.hasPanelTarget) this.panelTarget.classList.remove("open")
    if (this.hasOverlayTarget) this.overlayTarget.classList.remove("active")
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  handleResize() {
    if (window.innerWidth > 768) this.close()
  }
}