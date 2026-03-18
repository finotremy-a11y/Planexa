// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-hide flash après 5 secondes
    setTimeout(() => {
      this.element.style.opacity = '0'
      this.element.style.transform = 'translateX(100%)'
      this.element.style.transition = 'all 0.5s ease'
      setTimeout(() => this.element.remove(), 500)
    }, 5000)
  }
}
