import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "image", "placeholder", "remove"]

  preview() {
    const file = this.inputTarget.files && this.inputTarget.files[0]
    if (!file) return

    if (this.hasRemoveTarget) this.removeTarget.checked = false

    const objectUrl = URL.createObjectURL(file)
    this.imageTarget.src = objectUrl
    this.imageTarget.style.display = "block"
    if (this.hasPlaceholderTarget) this.placeholderTarget.style.display = "none"
  }

  toggleRemove() {
    if (!this.hasRemoveTarget || !this.hasImageTarget || !this.hasPlaceholderTarget) return

    if (this.removeTarget.checked) {
      this.imageTarget.style.display = "none"
      this.placeholderTarget.style.display = "flex"
      this.inputTarget.value = ""
    }
  }
}
