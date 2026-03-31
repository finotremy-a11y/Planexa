import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["clientLabel", "companyLabel", "radio"]

  connect() {
    this.refresh()
  }

  refresh() {
    const selected = this.radioTargets.find((radio) => radio.checked)
    const selectedRole = selected?.value

    this.clientLabelTarget.style.borderColor =
      selectedRole === "client" ? "var(--green-800)" : "var(--border)"
    this.companyLabelTarget.style.borderColor =
      selectedRole === "company_admin" ? "var(--green-800)" : "var(--border)"
  }
}