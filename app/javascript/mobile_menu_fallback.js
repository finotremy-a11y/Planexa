const bindPublicNavbar = () => {
  const button = document.getElementById("navbarHamburger")
  const links = document.getElementById("navbarLinks")
  const overlay = document.getElementById("navbarMobileOverlay")
  if (!button || !links || !overlay || button.dataset.mobileFallbackBound) return

  const setOpen = (open) => {
    links.classList.toggle("open", open)
    overlay.classList.toggle("open", open)
    document.body.classList.toggle("navbar-menu-open", open)
    button.setAttribute("aria-expanded", open ? "true" : "false")
  }

  button.addEventListener("click", (event) => {
    event.stopPropagation()
    setOpen(!links.classList.contains("open"))
  })

  overlay.addEventListener("click", () => setOpen(false))
  window.addEventListener("resize", () => {
    if (window.innerWidth > 768) setOpen(false)
  })

  button.dataset.mobileFallbackBound = "1"
}

const bindSidebar = ({ buttonId, panelSelector, overlayId }) => {
  const button = document.getElementById(buttonId)
  const panel = document.querySelector(panelSelector)
  const overlay = document.getElementById(overlayId)
  if (!button || !panel || !overlay || button.dataset.mobileFallbackBound) return

  const setOpen = (open) => {
    panel.classList.toggle("open", open)
    overlay.classList.toggle("active", open)
    button.setAttribute("aria-expanded", open ? "true" : "false")
  }

  button.addEventListener("click", () => setOpen(!panel.classList.contains("open")))
  overlay.addEventListener("click", () => setOpen(false))
  window.addEventListener("resize", () => {
    if (window.innerWidth > 768) setOpen(false)
  })

  button.dataset.mobileFallbackBound = "1"
}

const initMobileMenuFallbacks = () => {
  bindPublicNavbar()
  bindSidebar({ buttonId: "hamburgerBtn", panelSelector: ".sidebar", overlayId: "sidebarOverlay" })
  bindSidebar({ buttonId: "adminHamburgerBtn", panelSelector: ".admin-sidebar", overlayId: "adminSidebarOverlay" })
}

initMobileMenuFallbacks()
document.addEventListener("turbo:load", initMobileMenuFallbacks)