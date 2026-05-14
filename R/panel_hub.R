### Hub principal de la app (issue #74).
### Reemplaza la landing actual + sidebar lateral por una pantalla de entrada
### con 4 tarjetas grandes que llevan a las secciones de la app.
###
### Las tarjetas son actionLink con clase .hub-card-xl. El server las observa
### y actualiza el reactiveVal estado_app para cambiar de vista.

### Tarjeta XL para el hub. Más grande que landing_card (que se usaba en la
### landing del sidebar viejo). Estructura: ícono + título + descripción.
### Si disabled = TRUE, renderiza como div no clickable con estado visual
### "próximamente" (para Análisis transversal mientras no esté implementado).
hub_card_xl <- function(input_id,
                        icon_id,
                        titulo,
                        descripcion,
                        disabled = FALSE) {

  contenido <- tagList(
    icon(icon_id, class = "hub-card-xl-icon"),
    tags$h3(titulo, class = "hub-card-xl-title"),
    tags$p(descripcion, class = "hub-card-xl-desc")
  )

  if (isTRUE(disabled)) {
    div(
      class = "hub-card-xl hub-card-xl-disabled",
      `aria-disabled` = "true",
      contenido,
      tags$span(class = "hub-card-xl-badge", "Próximamente")
    )
  } else {
    actionLink(
      inputId = input_id,
      label = contenido,
      class = "hub-card-xl",
      role = "button",
      `aria-label` = paste0("Entrar a ", titulo)
    )
  }
}


### UI del hub: hero + grilla 2x2 + footer mínimo.
### El footer reemplaza al sidebar-footer del layout viejo (créditos, fuente,
### feedback). Se inyecta como hijo directo de un conditionalPanel en app.R.
panel_hub_ui <- function() {
  tagList(
    div(
      class = "hub-container",

      ### Header mínimo: solo el logo a la izquierda. Link externo a estacion-r.com.
      div(
        class = "hub-header",
        tags$a(
          href = "https://estacion-r.com/",
          target = "_blank",
          tags$img(src = "logos/logo_estacion_r_ancho.png",
                   class = "hub-header-logo",
                   alt = "Estación R")
        )
      ),

      ### Hero: propuesta de valor concreta para público amplio.
      div(
        class = "hub-hero",
        tags$h1(
          "Mercado de trabajo argentino, en clave de panel.",
          class = "hub-hero-title"
        ),
        tags$p(
          class = "hub-hero-subtitle",
          "Seguimos a las mismas personas trimestre a trimestre con datos de la ",
          tags$strong("EPH-INDEC"),
          " y mostramos cómo cambia su situación laboral en el tiempo."
        )
      ),

      ### Grilla 2x2 de tarjetas grandes. En mobile colapsa a 1 columna.
      div(
        class = "hub-grid-2x2",

        hub_card_xl(
          input_id = "go_panel",
          icon_id = "layer-group",
          titulo = "Análisis de panel",
          descripcion = "Seguimiento longitudinal de las mismas personas entre trimestres consecutivos. Condición de actividad, categoría ocupacional y formal/informal."
        ),

        hub_card_xl(
          input_id = "go_transversal",
          icon_id = "camera",
          titulo = "Análisis transversal",
          descripcion = "Foto del mercado de trabajo en un trimestre puntual: tasas de actividad, empleo y desocupación, calidad del empleo.",
          disabled = TRUE
        ),

        hub_card_xl(
          input_id = "go_metadata",
          icon_id = "book",
          titulo = "Metadata",
          descripcion = "Glosario de variables, definiciones metodológicas y links a documentación de la EPH."
        ),

        hub_card_xl(
          input_id = "go_datos",
          icon_id = "database",
          titulo = "Datos",
          descripcion = "Descarga del panel longitudinal completo en Parquet o CSV, más diccionario de variables."
        )
      ),

      ### Footer mínimo del hub: créditos, fuente, feedback, versión.
      ### Equivalente al sidebar-footer del layout viejo, ahora centrado al pie.
      div(
        class = "hub-footer",
        tags$p(
          class = "hub-footer-line",
          tags$strong("Datos: "),
          "EPH-INDEC · hasta 2025 T4"
        ),
        tags$p(
          class = "hub-footer-line",
          tags$strong("Feedback: "),
          tags$a(
            "pablotiscornia@estacion-r.com",
            href = "mailto:pablotiscornia@estacion-r.com?subject=Panel%20EPH",
            class = "hub-footer-link"
          )
        ),
        tags$p(
          class = "hub-footer-meta",
          "Hecho con R + Shiny por ",
          tags$a("Estación R", href = "https://estacion-r.com",
                 target = "_blank", class = "hub-footer-link"),
          " · App en desarrollo · ",
          tags$span(class = "hub-footer-version", paste0("v", APP_VERSION))
        )
      )
    )
  )
}
