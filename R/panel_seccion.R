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


### Shell del filter rail derecho: contiene la configuración global (Tipo de
### dúo, que migra acá desde el FAB) + un slot para los filtros locales NLQ
### de cada análisis. El rail aplica position: sticky con CSS.
###
### tipo_duo_input: el radioButtons del tipo de dúo (se construye en app.R
### porque es global).
### filtros_locales_ui: tagList con los filtros NLQ del módulo activo (puede
### ser NULL si la sección no tiene filtros, como Metadata o Datos).
section_filter_rail <- function(tipo_duo_input, filtros_locales_ui = NULL) {
  tags$aside(
    class = "filter-rail",
    `aria-labelledby` = "filter-rail-heading",

    ### Configuración global (Tipo de dúo).
    div(
      class = "filter-rail-section",
      tags$h6("Configuración global",
              id = "filter-rail-heading",
              class = "filter-rail-heading"),
      tipo_duo_input,
      tags$p(
        class = "filter-rail-helper",
        tags$strong("Intertrimestral: "),
        "T1-T2, T2-T3, T3-T4, T4-T1."
      ),
      tags$p(
        class = "filter-rail-helper",
        tags$strong("Interanual: "),
        "T1 año X vs T1 año X+1 (mismo trimestre, neutraliza estacionalidad)."
      )
    ),

    ### Filtros locales del análisis activo (si los hay).
    if (!is.null(filtros_locales_ui)) {
      div(
        class = "filter-rail-section",
        tags$h6("Filtros", class = "filter-rail-heading"),
        filtros_locales_ui
      )
    }
  )
}


### Trigger del filter rail en mobile (botón flotante "Filtros" bottom-right).
### En desktop el rail siempre está visible; en mobile se oculta y se abre con
### este botón vía offcanvas. La lógica de open/close se maneja con clases
### CSS toggleadas desde JS (data-bs-toggle nativo de Bootstrap 5).
filter_rail_mobile_trigger <- function() {
  tags$button(
    class = "filter-rail-mobile-trigger",
    type = "button",
    `data-bs-toggle` = "offcanvas",
    `data-bs-target` = "#filter-rail-offcanvas",
    `aria-controls` = "filter-rail-offcanvas",
    `aria-label` = "Abrir filtros",
    icon("sliders"),
    tags$span(class = "filter-rail-mobile-label", "Filtros")
  )
}


### Layout completo de una sección con sidebar interno + contenido + filter
### rail. Helper de conveniencia para las secciones que tienen los 3 (panel).
### Las secciones sin algunos elementos (datos, transversal) lo componen
### manualmente en app.R sin usar este helper.
section_layout_3col <- function(sidebar_internal, contenido, filter_rail) {
  bslib::layout_columns(
    col_widths = c(2, 7, 3),
    sidebar_internal,
    contenido,
    filter_rail,
    gap = "1rem"
  )
}
