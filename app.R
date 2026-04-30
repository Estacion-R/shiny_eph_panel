### Orden de carga:
###   00-libraries → paquetes
###   99-functions → lógica de negocio (necesita libs cargadas)
###   01-extract   → carga datos en memoria (df_eph_full, df_cond_act, df_tasas_mt)
###   02-transform → componentes UI compartidos (helpers NLQ, factor periodo)
###   03-hc-theme  → tema Highcharts Estación R
###   R/           → módulos Shiny (uno por análisis)
source("ETL/00-libraries.R")
source("ETL/99-functions.R")
source("ETL/01-extract.R")
source("ETL/02-transform.R")
source("ETL/03-hc-theme.R")
source("R/utils_analisis.R")
source("R/mod_analisis_cond_act.R")
source("R/mod_analisis_cat_ocup.R")
source("R/mod_analisis_formalidad.R")
source("R/panels_metadata.R")

waiting_screen <- tagList(
  spin_flower(),
  h4("Cargando datos...")
)

options(shiny.useragg = TRUE)
thematic_shiny(font = "auto")


### --------------------------------------------------------------------------
### Bloques de contenido estático (no reactivo): Sobre la app, Próximamente,
### +Info. Se inyectan como nav_panel dentro del navset_pill_list lateral.
### --------------------------------------------------------------------------

### Tarjetas clicables que llevan al usuario directo a cada eje de análisis.
### Renderizadas como actionLink para que el server pueda observar el click
### y redireccionar via bslib::nav_select() (ver server).
landing_card <- function(input_id, icon_id, titulo, descripcion) {
  actionLink(
    inputId = input_id,
    label = tagList(
      icon(icon_id, class = "landing-card-icon"),
      tags$h4(titulo, class = "landing-card-title"),
      tags$p(descripcion, class = "landing-card-desc")
    ),
    class = "landing-card"
  )
}

panel_sobre_la_app <- nav_panel(
  title = "Sobre la app",
  icon = icon("circle-info"),
  card(
    ### Hero: logo + propuesta de valor concreta para público amplio.
    div(
      class = "landing-hero",
      tags$a(
        href = "https://estacion-r.com/",
        tags$img(src = "logos/logo_estacion_r_ancho.png",
                 class = "landing-hero-logo",
                 alt = "Estación R")
      ),
      tags$h2(
        "Mercado de trabajo argentino, en clave de panel.",
        class = "landing-hero-title"
      ),
      tags$p(
        class = "landing-hero-subtitle",
        "Seguimos a las mismas personas trimestre a trimestre con datos de la ",
        tags$strong("EPH-INDEC"),
        " y mostramos cómo cambia su situación laboral en el tiempo."
      )
    ),

    ### Tarjetas de los 3 ejes de análisis. Click navega al panel.
    div(
      class = "landing-cards-row",
      tags$h3("Empezá a explorar", class = "landing-cards-heading"),
      div(
        class = "landing-cards-grid",
        landing_card(
          input_id = "go_cond_act",
          icon_id = "people-arrows",
          titulo = "Condición de actividad",
          descripcion = "Flujos entre ocupados, desocupados e inactivos."
        ),
        landing_card(
          input_id = "go_cat_ocup",
          icon_id = "user-tie",
          titulo = "Categoría ocupacional",
          descripcion = "Movilidad entre patrones, cuenta propia, asalariados y trabajadores familiares."
        ),
        landing_card(
          input_id = "go_formalidad",
          icon_id = "id-card",
          titulo = "Formal · Informal",
          descripcion = "Transiciones entre empleo formal e informal, definición clásica y ampliada (OIT 2023)."
        )
      )
    ),

    ### Sección informativa: qué es la EPH. Plegada bajo un title h3 para
    ### que el contenido técnico no domine la primera impresión.
    div(
      class = "landing-info",
      tags$h3("¿Qué es la EPH?", class = "landing-info-heading"),
      p(
        "La ",
        tags$strong(em("Encuesta Permanente de Hogares")),
        " (EPH) es la principal fuente de datos sobre mercado laboral del ",
        a("Sistema Estadístico Nacional (SEN)",
          href = "https://www.indec.gob.ar/indec/web/Institucional-Indec-SistemaEstadistico",
          target = "_blank"),
        " argentino. Aunque se la conoce sobre todo por la tasa de desocupación, permite caracterizar muchas otras dimensiones de las condiciones de vida."
      ),
      tags$h4("Foto vs. película"),
      p(
        "El abordaje habitual es ",
        tags$strong("transversal"),
        " (foto): describe a la población en un momento puntual, un trimestre. Pero la EPH también permite un análisis ",
        tags$strong("longitudinal"),
        " (película): seguir a las mismas personas en dos momentos consecutivos y medir cambios individuales. Si en el T1 alguien estaba ocupado, ¿sigue ocupado en el T2 o cambió de situación? Esa pregunta es la que esta app responde."
      ),
      tags$h4("¿Cómo es posible? El esquema 2-2-2"),
      p(
        "La muestra está diseñada con un esquema de rotación ",
        tags$strong("2-2-2"),
        ": cada vivienda es entrevistada ",
        tags$strong("dos"),
        " trimestres consecutivos, descansa ",
        tags$strong("dos"),
        " trimestres y vuelve a entrevistarse otros ",
        tags$strong("dos"),
        " trimestres antes de salir de la muestra. Este diseño permite construir paneles longitudinales con (teóricamente) el 50% de las personas en trimestres consecutivos y en el mismo trimestre de años consecutivos."
      ),
      p(
        class = "landing-info-cta",
        "Para detalles metodológicos, ver el ",
        tags$strong("Glosario"),
        " y las ",
        tags$strong("Definiciones"),
        " en el menú Metadata."
      )
    )
  )
)

### Helper para placeholders de análisis aún no implementados (Fases 3-4 del epic).
panel_proximamente <- function(titulo, icono_id, descripcion) {
  nav_panel(
    title = titulo,
    icon = icon(icono_id),
    card(
      class = "text-center",
      br(), br(),
      h2("Próximamente", class = "hero-title"),
      p(descripcion),
      p(em("Esta sección está en desarrollo.")),
      br(), br()
    )
  )
}

panel_info <- nav_menu(
  title = "+Info",
  icon = icon("circle-question"),
  nav_item(a("Documento metodológico: La nueva EPH",
             href = "https://www.indec.gob.ar/ftp/cuadros/sociedad/metodologia_eph_continua.pdf",
             target = "_blank")),
  nav_item(a("Paquete {eph}",
             href = "https://docs.ropensci.org/eph/",
             target = "_blank"))
)


### --------------------------------------------------------------------------
### UI principal: page_navbar minimalista con sidebar lateral (navset_pill_list)
### como navegación principal entre las secciones de la app.
### --------------------------------------------------------------------------

ui <- page_fillable(
  theme = bslib::bs_theme(brand = "_brand.yml"),
  tags$head(
    tags$link(rel = "icon", type = "image/svg+xml",
              href = "logos/isotipo_estacion_r.svg"),
    tags$link(rel = "stylesheet",
              href = "https://api.fontshare.com/v2/css?f[]=array@400,600,700&display=swap")
  ),
  useWaitress(color = "#405BFF"),
  include_styles,

  ### Navegación principal: sidebar lateral con todas las secciones.
  ### page_fillable + navset_pill_list(widget_size = "lg") da el patrón
  ### "sidebar fijo a la izquierda + contenido a la derecha".
  bslib::navset_pill_list(
    id = "main_nav",
    widths = c(2, 10),
    well = FALSE,

    ### Branding + título de la app dentro del sidebar.
    ### Usa el PNG de la guía de identidad (ver nota en panel_sobre_la_app).
    nav_item(
      div(
        class = "sidebar-brand",
        tags$a(
          href = "https://estacion-r.com/",
          tags$img(src = "logos/logo_estacion_r_ancho.png",
                   alt = "Estación R",
                   style = "max-width: 100%; height: auto; margin-bottom: 1rem;")
        )
      )
    ),

    ### Issue #31: agrupar Sobre la app + Glosario + Definiciones bajo
    ### un nav_menu "Metadata" para tener documentación consultable sin
    ### salir de la app.
    nav_menu(
      title = "Metadata",
      icon = icon("book"),
      panel_sobre_la_app,
      panel_glosario,
      panel_definiciones
    ),

    ### Análisis de panel: agrupados bajo un nav_menu colapsable.
    nav_menu(
      title = "Análisis de panel",
      icon = icon("layer-group"),
      nav_panel(
        title = "Condición de actividad",
        icon = icon("people-arrows"),
        mod_cond_act_ui("cond_act")
      ),
      nav_panel(
        title = "Categoría ocupacional",
        icon = icon("user-tie"),
        mod_cat_ocup_ui("cat_ocup")
      ),
      nav_panel(
        title = "Formal / Informal",
        icon = icon("id-card"),
        mod_formalidad_ui("formalidad")
      )
    ),

    panel_info,

    ### Footer con créditos, fuente y feedback. Como nav_item al pie del
    ### sidebar para que esté siempre visible sin estorbar la navegación.
    nav_item(
      div(
        class = "sidebar-footer",
        tags$p(
          tags$span(class = "sidebar-footer-label", "Datos:"),
          tags$br(),
          "EPH-INDEC · hasta 2025 T4"
        ),
        tags$p(
          tags$span(class = "sidebar-footer-label", "Feedback:"),
          tags$br(),
          tags$a(
            "pablotiscornia@estacion-r.com",
            href = "mailto:pablotiscornia@estacion-r.com?subject=Panel%20EPH",
            class = "sidebar-footer-link"
          )
        ),
        tags$p(
          class = "sidebar-footer-meta",
          "Hecho con R + Shiny por ",
          tags$a("Estación R", href = "https://estacion-r.com",
                 target = "_blank", class = "sidebar-footer-link"),
          " · App en desarrollo"
        )
      )
    )
  )
)


### --------------------------------------------------------------------------
### Server: solo orquestación. Cada análisis vive en su propio módulo.
### --------------------------------------------------------------------------

server <- function(input, output, session) {

  mod_cond_act_server("cond_act")
  mod_cat_ocup_server("cat_ocup")
  mod_formalidad_server("formalidad")

  ### Navegación desde las tarjetas del landing. Cada actionLink dispara
  ### bslib::nav_select() para cambiar la pestaña activa del navset_pill_list
  ### lateral. ignoreInit evita que se dispare al cargar la app.
  observeEvent(input$go_cond_act, ignoreInit = TRUE, {
    bslib::nav_select(id = "main_nav", selected = "Condición de actividad")
  })
  observeEvent(input$go_cat_ocup, ignoreInit = TRUE, {
    bslib::nav_select(id = "main_nav", selected = "Categoría ocupacional")
  })
  observeEvent(input$go_formalidad, ignoreInit = TRUE, {
    bslib::nav_select(id = "main_nav", selected = "Formal / Informal")
  })

  ### Tabla del Glosario (issue #31). Se renderiza una sola vez,
  ### contenido estático.
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
}


# Run the application
shinyApp(ui = ui, server = server)
