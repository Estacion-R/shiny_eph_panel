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
source("R/mod_analisis_cond_act.R")
source("R/mod_analisis_cat_ocup.R")

library(shinyalert)

waiting_screen <- tagList(
  spin_flower(),
  h4("Bancame un toque...")
)

options(shiny.useragg = TRUE)
thematic_shiny(font = "auto")


### --------------------------------------------------------------------------
### Bloques de contenido estático (no reactivo): Sobre la app, Próximamente,
### +Info. Se inyectan como nav_panel dentro del navset_pill_list lateral.
### --------------------------------------------------------------------------

panel_sobre_la_app <- nav_panel(
  title = "Sobre la app",
  icon = icon("circle-info"),
  card(
    br(),
    titlePanel(title = div(
      tags$a(
        href = "https://linktr.ee/estacion_r",
        tags$img(src = "logos/logo_completo_estacion_r.svg",
                 height = 80, alt = "Estación R")
      ),
      align = "center"
    )),
    br(),
    tags$blockquote(
      "En la presente aplicación se va a poder estudiar el comportamiento del mercado de trabajo bajo la estrategia de análisis de panel. Para esto, hablemos un poco de la E-P-H"
    ),
    h1("La E-P-H", class = "hero-title"),
    p(
      strong(em("La Encuesta Permanente de Hogares")),
      "es una de las fuentes de información sociodemográfica más importante del",
      a("Sistema Estadístico Nacional (SEN)",
        href = "https://www.indec.gob.ar/indec/web/Institucional-Indec-SistemaEstadistico"),
      "Argentino. Si bien este operativo es más conocido por la Tasa de Desocupación",
      a("[1], ", href = "#footnote-1"),
      "el abanico de indicadores que se pueden obtener para caracterizar las condiciones de vida de la población es muy amplio."
    ),
    p(
      "Dos estrategias de análisis son plausible de abordar al momento de querer caracterizar a una población determinada. La primera es el",
      strong("Análisis Transversal,"),
      "entendido como una forma de leer los datos en clave de 'foto'. Esta es el abordaje para el cual fue diseñada la encuesta, aunque no el único."
    ),
    p(
      "Una segunda manera de interpretar la información es mediante el",
      strong("Anáisis Longitudinal"),
      "en el cual la lectura es en clave de 'película'. Esto es, para una misma población, observo su evolución respecto al indicador seleccionado. Para ejemplificar, bajo este análisis puedo saber si la población ocupada que entrevisté en el primer trimestre del 2023 se encuentra en la misma situación o la ha modificado (pasó a la desocupación o inactividad) en el trimestre siguiente"
    ),
    br(),
    h4("Análisis longitudinal de la EPH."),
    p(
      "Esta forma de interpretar los datos se debe gracias al",
      strong("esquema de rotación "),
      "bajo el cual fue diseñada la muestra, conocido como '2-2-2'. Este esquema implica que una vivienda es seleccionada para ser entrevistada 4 veces. En una primera instancia participa del operativo durante los primeros",
      strong("dos "),
      "trimestres de forma consecutiva, descansa los",
      strong("dos "),
      "trimestres siguientes y vuelve a participar por",
      strong("dos "),
      "trimestres más, para finalmente salir de la muestra y no volver a ser seleccionada. Al usar un esquema como el descripto, la muestra plausible de ser utilizada para el análisis de panel (longitudinal) es (teóricamente) del 50% para trimestres consecutivos (ejemplo, trimestre 1 y 2 del 2022) y para un mismo trimestre de años consecutivo (trimestre 1 del año 2022 y 2023)"
    ),
    p(id = "footnote-1",
      "1 Porcentaje entre la población desocupada y la población económicamente activa.")
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

    ### Branding + título de la app dentro del sidebar
    nav_item(
      div(
        class = "sidebar-brand",
        tags$a(
          href = "https://linktr.ee/estacion_r",
          tags$img(src = "logos/logo_completo_estacion_r.svg",
                   height = 50, alt = "Estación R",
                   style = "margin-bottom: 1rem;")
        )
      )
    ),

    panel_sobre_la_app,

    ### Header de sección "Análisis"
    nav_item(
      tags$div(
        class = "sidebar-section-label",
        style = "margin-top: 1rem; font-size: 0.85rem; color: #666; text-transform: uppercase; letter-spacing: 0.05em;",
        "Análisis de panel"
      )
    ),

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

    panel_proximamente(
      titulo = "Formal / Informal",
      icono_id = "id-card",
      descripcion = "Movilidad entre empleo formal e informal, según definición OIT (asalariados con aportes + cuenta propia con monotributo)."
    ),

    panel_info
  )
)


### --------------------------------------------------------------------------
### Server: solo orquestación. Cada análisis vive en su propio módulo.
### --------------------------------------------------------------------------

server <- function(input, output, session) {

  shinyalert(
    title = "Buenas!",
    text = "Esta aplicación está en desarrollo. Si algo no está funcionando, se puede mejorar o incluso tenés una idea para agregar, podés escribirme a pablotiscornia@estacion-r.com",
    size = "s",
    closeOnEsc = TRUE,
    closeOnClickOutside = FALSE,
    html = FALSE,
    type = "info",
    showConfirmButton = TRUE,
    showCancelButton = FALSE,
    confirmButtonText = "JOYA",
    confirmButtonCol = "#405BFF",
    timer = 0,
    imageUrl = "logos/isotipo_estacion_r.svg",
    imageWidth = 80,
    imageHeight = 80,
    animation = TRUE
  )

  mod_cond_act_server("cond_act")
  mod_cat_ocup_server("cat_ocup")
}


# Run the application
shinyApp(ui = ui, server = server)
