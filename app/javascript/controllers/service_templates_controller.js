import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "description", "duration", "price"]

  fill(event) {
    const button = event.currentTarget
    this.nameTarget.value = button.dataset.templateName || ""
    this.descriptionTarget.value = button.dataset.templateDescription || ""
    this.durationTarget.value = button.dataset.templateDuration || ""
    this.priceTarget.value = button.dataset.templatePrice || ""
    this.nameTarget.focus()
  }
}