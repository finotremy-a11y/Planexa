import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categorySelect", "specialtySelect"]
  static values = { specialtyUrl: String }

  connect() {
    this.updateSpecialties()
  }

  async updateSpecialties() {
    const category = this.categorySelectTarget.value
    if (!category) return

    try {
      const response = await fetch(
        `${this.specialtyUrlValue}?category=${category}`,
        { headers: { Accept: "application/json" } }
      )

      if (!response.ok) throw new Error("Failed to fetch specialties")

      const specialties = await response.json()
      this.populateSpecialties(specialties)
    } catch (error) {
      console.error("Error updating specialties:", error)
    }
  }

  populateSpecialties(specialties) {
    const select = this.specialtySelectTarget
    const currentValue = select.value

    // Garder l'option avec le label "Selectionner une specialite"
    const blankOption = Array.from(select.options).find(
      opt => opt.value === ""
    )

    // Supprimer toutes les options sauf la première
    while (select.options.length > 1) {
      select.remove(1)
    }

    // Ajouter les nouvelles options
    specialties.forEach((specialty) => {
      const option = document.createElement("option")
      option.value = specialty
      option.textContent = specialty
      select.appendChild(option)
    })

    // Tenter de restaurer la valeur précédente si elle existe toujours
    if (specialties.includes(currentValue)) {
      select.value = currentValue
    } else {
      select.value = ""
    }
  }

  categoryChanged() {
    this.updateSpecialties()
  }
}
