### Orden de carga:
###   00-libraries → paquetes
###   99-functions → lógica de negocio (necesita libs cargadas)
###   01-extract   → carga datos en memoria (df_eph_full, df_cond_act, df_tasas_mt)
###   02-transform → componentes UI compartidos (helpers NLQ, factor periodo)
###   03-hc-theme  → tema Highcharts Estación R
###   R/           → módulos Shiny (uno por análisis) + helpers de layout
source("ETL/00-libraries.R")
source("ETL/99-functions.R")
source("ETL/01-extract.R")
source("ETL/02-transform.R")
source("ETL/03-hc-theme.R")
source("R/utils_analisis.R")
source("R/configs_analisis.R")
source("R/mod_analisis.R")
source("R/mod_calidad_panel.R")
source("R/utils_analytics.R")
source("R/panels_metadata.R")
source("R/panel_descarga.R")
source("R/version.R")
source("R/panel_hub.R")
source("R/panel_seccion.R")

waiting_screen <- tagList(
  spin_flower(),
  h4("Cargando datos...")
)

### thematic_shiny() y options(shiny.useragg) removidos para reducir RAM.
### Si vuelve a hacer falta sincronizar tema de ggplot con bslib, reactivar
### library(thematic) en ETL/00-libraries.R y la llamada acá.


### --------------------------------------------------------------------------
### Links externos para la sección Metadata (issue #31). Se mantienen como
### nav_item porque viajan dentro del navset_pill_list interno de Metadata.
### --------------------------------------------------------------------------

nav_item_doc_indec <- nav_item(
  a(icon("file-pdf"), " Documento metodológico INDEC",
    href = "https://www.indec.gob.ar/ftp/cuadros/sociedad/metodologia_eph_continua.pdf",
    target = "_blank")
)
nav_item_paquete_eph <- nav_item(
  a(icon("r-project"), " Paquete {eph}",
    href = "https://docs.ropensci.org/eph/",
    target = "_blank")
)


### --------------------------------------------------------------------------
### UI principal: patrón hub-and-spoke (issue #74).
###
### La pantalla de entrada es un Hub con 4 tarjetas grandes (Análisis de
### panel, Análisis transversal, Metadata, Datos). Cada tarjeta entra a una
### vista de sección con su sidebar interno y contenido. El estado se
### maneja con un reactiveVal en el server y conditionalPanel decide qué
### vista mostrar. Ver R/panel_hub.R y R/panel_seccion.R para los helpers.
### --------------------------------------------------------------------------

ui <- page_fillable(
  theme = bslib::bs_theme(brand = "_brand.yml"),
  tags$head(
    tags$link(rel = "icon", type = "image/svg+xml",
              href = "logos/isotipo_estacion_r.svg"),
    tags$link(rel = "stylesheet",
              href = "https://api.fontshare.com/v2/css?f[]=array@400,600,700&display=swap"),
    tags$script(src = "reflow_charts.js")
  ),
  ga4_head_tag(),
  useWaitress(color = "#405BFF"),
  include_styles,

  ### Outputs de control para conditionalPanel. No son visuales: solo
  ### exponen el estado del reactiveVal al cliente para que las condiciones
  ### JS puedan evaluar qué vista está activa.
  div(style = "display: none;",
      textOutput("current_view"),
      textOutput("current_subseccion")),

  ### ----- Vista "hub" -----
  ### La condición acepta 'undefined' para evitar que la pantalla quede gris
  ### en el primer render (mientras el output.current_view aún no llegó al
  ### cliente). Default visual = hub.
  conditionalPanel(
    condition = "(typeof output.current_view === 'undefined') || (output.current_view == 'hub')",
    panel_hub_ui()
  ),

  ### ----- Vista "panel": análisis longitudinales -----
  conditionalPanel(
    condition = "output.current_view == 'panel'",
    div(
      class = "section-vista",
      section_topbar("Análisis de panel"),
      bslib::layout_columns(
        col_widths = c(2, 10),
        gap = "1rem",

        ### Sidebar interno: sub-secciones (dinámicas para marcar item
        ### activo) + toggle "Modo" al pie (estático para preservar estado).
        div(
          class = "section-sidebar-wrap",
          uiOutput("sidebar_panel"),
          div(
            class = "section-sidebar-mode",
            tags$h6("Modo", class = "section-sidebar-mode-heading"),
            radioButtons(
              inputId = "tipo_duo",
              label   = NULL,
              choices = c(
                "Intertrimestral" = "trimestral",
                "Interanual"      = "anual"
              ),
              selected = "trimestral"
            ),
            bslib::popover(
              tags$span(
                class = "section-sidebar-mode-info",
                bsicons::bs_icon("info-circle"),
                " ¿Qué es?"
              ),
              title = "Tipo de dúo",
              tags$p(
                tags$strong("Intertrimestral: "),
                "T1-T2, T2-T3, T3-T4, T4-T1 dentro del mismo año o entre años contiguos.",
                style = "font-size: 0.85em; margin-bottom: 0.5rem;"
              ),
              tags$p(
                tags$strong("Interanual: "),
                "T1 año X vs T1 año X+1 (mismo trimestre, neutraliza estacionalidad).",
                style = "font-size: 0.85em; margin-bottom: 0;"
              ),
              placement = "right"
            )
          )
        ),

        ### Contenido del análisis activo. Los 4 módulos están siempre
        ### montados; conditionalPanel sólo cambia visibilidad. Esto
        ### preserva el estado de los inputs entre cambios de sub-sección.
        div(
          class = "section-content",

          ### Badge contextual: muestra el modo activo arriba del contenido,
          ### así el usuario nunca pierde de vista qué "Tipo de dúo" está
          ### viendo en los gráficos.
          uiOutput("badge_modo_activo"),

          conditionalPanel(
            "output.current_subseccion == 'cond_act'",
            mod_analisis_ui("cond_act", config_cond_act)
          ),
          conditionalPanel(
            "output.current_subseccion == 'cat_ocup'",
            mod_analisis_ui("cat_ocup", config_cat_ocup)
          ),
          conditionalPanel(
            "output.current_subseccion == 'formalidad'",
            mod_analisis_ui("formalidad", config_formalidad)
          ),
          conditionalPanel(
            "output.current_subseccion == 'calidad'",
            mod_calidad_panel_ui("calidad")
          )
        )
      )
    )
  ),

  ### ----- Vista "transversal": placeholder, en roadmap -----
  conditionalPanel(
    condition = "output.current_view == 'transversal'",
    div(
      class = "section-vista",
      section_topbar("Análisis transversal"),
      card(
        class = "text-center proximamente-card",
        br(), br(),
        h2("Próximamente", class = "hero-title"),
        p("Las tasas básicas (actividad, empleo, desocupación) y la calidad del empleo van a estar disponibles próximamente como análisis transversal."),
        p(em("Esta sección está en desarrollo.")),
        br(), br()
      )
    )
  ),

  ### ----- Vista "metadata" -----
  conditionalPanel(
    condition = "output.current_view == 'metadata'",
    div(
      class = "section-vista",
      section_topbar("Metadata"),
      ### Reusamos navset_pill_list a nivel sección: hace de sidebar interno
      ### sin necesidad de reescribir panel_glosario / panel_definiciones.
      bslib::navset_pill_list(
        id = "metadata_nav",
        widths = c(2, 10),
        well = FALSE,
        panel_glosario,
        panel_definiciones,
        nav_item_doc_indec,
        nav_item_paquete_eph
      )
    )
  ),

  ### ----- Vista "datos" -----
  conditionalPanel(
    condition = "output.current_view == 'datos'",
    div(
      class = "section-vista",
      section_topbar("Datos"),
      panel_descarga_content
    )
  ),

  ### Banner de consent + handler de GA4 (issue #38). Solo se renderizan
  ### si GA4_MEASUREMENT_ID está configurado en R/utils_analytics.R; si
  ### no, devuelven NULL y no impactan la app.
  cookie_consent_banner(),
  analytics_js()
)


### --------------------------------------------------------------------------
### Server: orquestación del estado hub-and-spoke + montaje de módulos.
### --------------------------------------------------------------------------

server <- function(input, output, session) {

  ### --- State machine -----------------------------------------------------
  ###
  ### vista: "hub" | "panel" | "transversal" | "metadata" | "datos"
  ### subseccion: dentro de "panel" puede ser "cond_act", "cat_ocup",
  ###             "formalidad" o "calidad". En las demás vistas es NULL.
  estado_app <- reactiveVal(list(vista = "hub", subseccion = NULL))

  ### Exponer estado al cliente para que conditionalPanel lo lea.
  output$current_view <- renderText({ estado_app()$vista })
  outputOptions(output, "current_view", suspendWhenHidden = FALSE)

  output$current_subseccion <- renderText({
    ss <- estado_app()$subseccion
    if (is.null(ss)) "" else ss
  })
  outputOptions(output, "current_subseccion", suspendWhenHidden = FALSE)

  ### --- Tipo de dúo (global, viene del filter rail) ---------------------
  tipo_duo <- reactive({
    val <- input$tipo_duo
    if (is.null(val) || !nzchar(val)) "trimestral" else val
  })

  ### --- Módulos de análisis ----------------------------------------------
  ### Se montan al inicio. conditionalPanel sólo cambia visibilidad, lo
  ### que evita re-instanciar los reactives al cambiar sub-sección y
  ### preserva el estado de los inputs del usuario.
  mod_analisis_server("cond_act",   config_cond_act,   tipo_duo = tipo_duo)
  mod_analisis_server("cat_ocup",   config_cat_ocup,   tipo_duo = tipo_duo)
  mod_analisis_server("formalidad", config_formalidad, tipo_duo = tipo_duo)
  mod_calidad_panel_server("calidad", tipo_duo = tipo_duo)

  ### --- Badge contextual del modo activo ------------------------------
  ### Aparece arriba del contenido en la vista "panel" para que el modo
  ### "Intertrimestral/Interanual" sea visible sin tener que mirar el
  ### sidebar. Cambia automático con input$tipo_duo.
  output$badge_modo_activo <- renderUI({
    modo <- tipo_duo()
    label <- if (modo == "trimestral") "Intertrimestral" else "Interanual"
    tags$span(
      class = "badge-modo-duo",
      bsicons::bs_icon("calendar-week"),
      tags$span(class = "badge-modo-duo-label", label)
    )
  })

  ### --- Sidebar interno de "panel" (dinámico con item activo) ----------
  output$sidebar_panel <- renderUI({
    ss <- estado_app()$subseccion %||% "cond_act"
    section_sidebar_internal(list(
      section_sidebar_item("go_sub_cond_act",   "people-arrows",
                           "Condición de actividad",
                           activa = ss == "cond_act"),
      section_sidebar_item("go_sub_cat_ocup",   "user-tie",
                           "Categoría ocupacional",
                           activa = ss == "cat_ocup"),
      section_sidebar_item("go_sub_formalidad", "id-card",
                           "Formal · Informal",
                           activa = ss == "formalidad"),
      section_sidebar_item("go_sub_calidad",    "magnifying-glass-chart",
                           "Calidad de la muestra",
                           activa = ss == "calidad")
    ))
  })

  ### --- Click handlers: tarjetas del hub --------------------------------
  observeEvent(input$go_panel, ignoreInit = TRUE, {
    estado_app(list(vista = "panel", subseccion = "cond_act"))
  })
  observeEvent(input$go_metadata, ignoreInit = TRUE, {
    estado_app(list(vista = "metadata", subseccion = NULL))
  })
  observeEvent(input$go_datos, ignoreInit = TRUE, {
    estado_app(list(vista = "datos", subseccion = NULL))
  })
  ### "Análisis transversal" está disabled en el hub (no dispara input),
  ### pero el handler queda preparado para cuando se habilite la sección.
  observeEvent(input$go_transversal, ignoreInit = TRUE, {
    estado_app(list(vista = "transversal", subseccion = NULL))
  })

  ### --- Click handlers: sidebar interno de "panel" ----------------------
  observeEvent(input$go_sub_cond_act, ignoreInit = TRUE, {
    estado_app(list(vista = "panel", subseccion = "cond_act"))
  })
  observeEvent(input$go_sub_cat_ocup, ignoreInit = TRUE, {
    estado_app(list(vista = "panel", subseccion = "cat_ocup"))
  })
  observeEvent(input$go_sub_formalidad, ignoreInit = TRUE, {
    estado_app(list(vista = "panel", subseccion = "formalidad"))
  })
  observeEvent(input$go_sub_calidad, ignoreInit = TRUE, {
    estado_app(list(vista = "panel", subseccion = "calidad"))
  })

  ### --- Click handler: "← Inicio" ---------------------------------------
  observeEvent(input$back_to_hub, ignoreInit = TRUE, {
    estado_app(list(vista = "hub", subseccion = NULL))
  })

  ### --- Reflow Highcharts al cambiar vista/sub-sección -----------------
  ### El handler JS (www/reflow_charts.js) itera todos los charts visibles
  ### y llama a chart.reflow() para que respeten el tamaño de su contenedor
  ### después del cambio de display:none -> block del conditionalPanel.
  observeEvent(estado_app(), ignoreInit = TRUE, {
    session$sendCustomMessage("reflow_charts", TRUE)
  })

  ### --- URL state: escribir el estado en el query string ---------------
  ### Permite F5/bookmark/share de la vista activa. El botón "atrás" del
  ### browser no navega entre vistas internas (asumido como costo, ver
  ### plan v2 sección "Riesgos asumidos").
  observeEvent(estado_app(), ignoreInit = TRUE, {
    s <- estado_app()
    q <- if (s$vista == "hub") {
      "?"
    } else if (is.null(s$subseccion)) {
      paste0("?v=", s$vista)
    } else {
      paste0("?v=", s$vista, "&s=", s$subseccion)
    }
    updateQueryString(q, mode = "push")
  })

  ### --- URL state: leer el estado inicial del query string -------------
  observe({
    q <- parseQueryString(session$clientData$url_search)
    vistas_validas <- c("panel", "transversal", "metadata", "datos")
    if (!is.null(q$v) && q$v %in% vistas_validas) {
      estado_app(list(vista = q$v,
                      subseccion = if (is.null(q$s)) NULL else q$s))
    }
  })

  ### --- Tabla del Glosario (issue #31) ---------------------------------
  output$metadata_glosario_table <- gt::render_gt({
    gt::gt(glosario_vars) |>
      gt::tab_options(
        table.font.names = "Ubuntu, sans-serif",
        table.font.size = "0.9em",
        column_labels.font.weight = "600",
        column_labels.background.color = "#F7F7F7"
      ) |>
      gt::cols_width(
        Variable ~ gt::px(110),
        Etiqueta ~ gt::px(180),
        Descripción ~ gt::px(360)
      ) |>
      gt::tab_style(
        style = gt::cell_text(font = "Ubuntu Mono, monospace", weight = "600"),
        locations = gt::cells_body(columns = Variable)
      )
  })

  ### --------------------------------------------------------------------
  ### Descargas del panel longitudinal (issue #35).
  ### El parquet y el CSV gzip se sirven copiando archivos de
  ### data_output/ (sin procesamiento en runtime). El diccionario se
  ### genera on-demand a partir del tibble columnas_panel_runtime.
  ### El tracking GA4 se dispara client-side (ver download_btn_tracked).
  ### --------------------------------------------------------------------

  servir_archivo <- function(ruta_relativa, nombre_descarga) {
    shiny::downloadHandler(
      filename = function() nombre_descarga,
      content  = function(file) file.copy(ruta_relativa, file),
      contentType = NA
    )
  }

  output$descarga_panel_runtime_parquet <- servir_archivo(
    "data_output/panel_runtime.parquet",
    paste0("eph_panel_runtime_", format(Sys.Date(), "%Y%m%d"), ".parquet"))

  output$descarga_panel_runtime_csv <- servir_archivo(
    "data_output/panel_runtime.csv.gz",
    paste0("eph_panel_runtime_", format(Sys.Date(), "%Y%m%d"), ".csv.gz"))

  ### Panel anual (issue #47).
  output$descarga_panel_runtime_anual_parquet <- servir_archivo(
    "data_output/panel_runtime_anual.parquet",
    paste0("eph_panel_runtime_anual_", format(Sys.Date(), "%Y%m%d"), ".parquet"))

  output$descarga_panel_runtime_anual_csv <- servir_archivo(
    "data_output/panel_runtime_anual.csv.gz",
    paste0("eph_panel_runtime_anual_", format(Sys.Date(), "%Y%m%d"), ".csv.gz"))

  output$descarga_diccionario_csv <- shiny::downloadHandler(
    filename = function() {
      paste0("eph_panel_diccionario_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      readr::write_csv(columnas_panel_runtime, file)
    },
    contentType = "text/csv"
  )
}


# Run the application
shinyApp(ui = ui, server = server)
