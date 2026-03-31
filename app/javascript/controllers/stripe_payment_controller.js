import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["paymentElement", "errors", "submit"]
  static values = {
    publishableKey: String,
    clientSecret: String,
    returnUrl: String,
    processingText: String,
    retryText: String
  }

  connect() {
    this.initialized = false
    this.mountWhenReady()
  }

  mountWhenReady() {
    if (this.initialized) return

    if (window.Stripe) {
      this.mountStripe()
      return
    }

    const script = document.querySelector('script[src="https://js.stripe.com/v3/"]')
    if (!script) return

    this.onStripeLoad = () => this.mountStripe()
    script.addEventListener("load", this.onStripeLoad, { once: true })
  }

  disconnect() {
    const script = document.querySelector('script[src="https://js.stripe.com/v3/"]')
    if (script && this.onStripeLoad) script.removeEventListener("load", this.onStripeLoad)
  }

  mountStripe() {
    if (this.initialized || !window.Stripe) return

    this.stripe = window.Stripe(this.publishableKeyValue)
    const appearance = {
      theme: "stripe",
      variables: {
        colorPrimary: "#2C5F2E",
        borderRadius: "8px",
        fontFamily: "DM Sans, system-ui, sans-serif"
      }
    }

    this.elements = this.stripe.elements({
      clientSecret: this.clientSecretValue,
      appearance
    })

    this.paymentField = this.elements.create("payment")
    this.paymentField.mount(this.paymentElementTarget)
    this.initialized = true
  }

  async submit(event) {
    event.preventDefault()
    if (!this.initialized) return

    this.submitTarget.disabled = true
    this.submitTarget.textContent = this.processingTextValue
    this.errorsTarget.style.display = "none"

    const { error } = await this.stripe.confirmPayment({
      elements: this.elements,
      confirmParams: {
        return_url: this.returnUrlValue
      }
    })

    if (error) {
      this.errorsTarget.textContent = error.message
      this.errorsTarget.style.display = "block"
      this.submitTarget.disabled = false
      this.submitTarget.textContent = this.retryTextValue
    }
  }
}