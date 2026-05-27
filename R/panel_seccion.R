### Helpers para componer la vista "sección" del patrón hub-and-spoke (issue #74).
###
### Cada sección de la app (Análisis de panel, Análisis transversal, Metadata,
### Datos) comparte la misma estructura: top bar con "← Inicio" + título,
### opcional sidebar interno con sub-secciones, contenido principal, opcional
### filter rail sticky a la derecha.
###
### Estos helpers exponen las piezas reusables. app.R las compone con
### conditionalPanel según la vista activa.


### Link "← Inicio" del topbar. actionLink que el server observa para volver
### al hub. Se usa también de forma standalone si una sección no tiene topbar
### completo (ej. mobile).
back_to_hub_link <- function(input_id = "back_to_hub") {
  actionLink(
    inputId = input_id,
    label = tagList(
      icon("arrow-left", class = "section-topbar-back-icon"),
      tags$span("Inicio", class = "section-topbar-back-text")
    ),
    class = "section-topbar-back",
    `aria-label` = "Volver al inicio"
  )
}


### Top bar de una sección: link al hub + título de la sección.
### El título puede ser dinámico (uiOutput) si depende de la sub-sección
### activa, o estático.
section_topbar <- function(titulo, back_input_id = "back_to_hub") {
  div(
    class = "section-topbar",
    back_to_hub_link(back_input_id),
    tags$span(class = "section-topbar-sep", "·"),
    tags$h2(titulo, class = "section-topbar-title")
  )
}


### Item del sidebar interno de una sección. actionLink que el server observa
### para cambiar la sub-sección activa (input.<input_id> dispara el cambio).
### activa: si TRUE, recibe la clase visual de "current".
section_sidebar_item <- function(input_id, icon_id, label, activa = FALSE) {
  cls <- if (isTRUE(activa)) {
    "section-sidebar-internal-item section-sidebar-internal-item-active"
  } else {
    "section-sidebar-internal-item"
  }
  actionLink(
    inputId = input_id,
    label = tagList(
      icon(icon_id, class = "section-sidebar-internal-icon"),
      tags$span(label)
    ),
    class = cls,
    role = "button"
  )
}


### Sidebar interno de una sección. Lista vertical de sub-secciones, una al
### lado de la otra. Se usa dentro de un layout_columns o grid CSS.
### items: lista de tagList() generados por section_sidebar_item().
section_sidebar_internal <- function(items, titulo = NULL) {
  tags$aside(
    class = "section-sidebar-internal",
    `aria-label` = "Sub-secciones",
    if (!is.null(titulo)) tags$h6(titulo, class = "section-sidebar-internal-heading"),
    do.call(tagList, items)
  )
}
