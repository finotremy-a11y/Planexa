import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "copyButton"]

  async copy() {
    const text = this.sourceTarget.value

    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text)
    } else {
      this.sourceTarget.select()
      document.execCommand("copy")
    }

    const original = this.copyButtonTarget.textContent
    this.copyButtonTarget.textContent = "✓ Copie !"
    window.setTimeout(() => {
      this.copyButtonTarget.textContent = original
    }, 2000)
  }

  print() {
    window.print()
  }
}