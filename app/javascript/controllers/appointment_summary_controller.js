import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "name", "duration", "price"]
  static values = { quote: String }

  connect() {
    this.refresh()
  }

  refresh(event) {
    const selected = event?.target || this.radioTargets.find((radio) => radio.checked) || this.radioTargets[0]
    if (!selected) return

    this.nameTarget.textContent = selected.dataset.serviceName || "-"
    this.durationTarget.textContent = `${selected.dataset.serviceDuration || "-"} min`

    const amount = Number(selected.dataset.servicePrice || 0)
    this.priceTarget.textContent = amount > 0
      ? `${(amount / 100).toFixed(2).replace(".", ",")} €`
      : this.quoteValue
  }
}