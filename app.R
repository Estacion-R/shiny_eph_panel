### Orden de carga:
###   00-libraries → paquetes
###   99-functions → lógica de negocio (necesita libs cargadas)
###   01-extract   → carga datos en memoria (df_eph_full, df_cond_act, df_tasas_mt)
###   02-transform → componentes UI (necesita los datos cargados)
source("ETL/00-libraries.R")
source("ETL/99-functions.R")
source("ETL/01-extract.R")
source("ETL/02-transform.R")
source("ETL/03-hc-theme.R")

library(shinyalert)

waiting_screen <- tagList(
  spin_flower(),
  h4("Bancame un toque...")
)

options(shiny.useragg = TRUE)
thematic_shiny(font = "auto")

# Define UI for application that draws a histogram
ui <- page_navbar(

  # Tema oficial Estación R desde _brand.yml (fuente única de verdad).
  # Sync con: Proyectos/_activos/identidad_visual/_brand.yml
  theme = bslib::bs_theme(brand = "_brand.yml"),

  header = tagList(
    tags$head(
      tags$link(rel = "icon", type = "image/svg+xml",
                href = "logos/isotipo_estacion_r.svg")
    ),
    useWaitress(color = "#405BFF")
  ),

  title = div(
    tags$a(
      href = 'https://linktr.ee/estacion_r',
      tags$img(src = 'logos/logo_completo_estacion_r.svg',
               height = 40, alt = "Estación R")
    ),
    align = "left"
  ),
  window_title = "EPH Panel · Estación R",
  navbar_options = navbar_options(underline = TRUE),
  
  nav_panel(
    icon = icon("circle-info"),
    title = "Sobre la App", 
    card(
      class = "bg-dark",
      #padding = "20px", gap = "20px",
      
      
      br(),
      
      titlePanel(title = div(
        tags$a(
          href = 'https://linktr.ee/estacion_r',
          tags$img(src = 'logos/logo_completo_estacion_r.svg',
                   height = 80, alt = "Estación R")
        ),
        align = "center"
      )),
      
      br(),
      
      tags$blockquote("En la presente aplicación se va a poder estudiar el comportamiento del mercado de trabajo bajo la estrategia de análisis de panel. Para esto, hablemos un poco de la E-P-H"
      ),
      
      #br(),
      
      h1("La E-P-H"),
      p(
        strong(em("La Encuesta Permanente de Hogares")), 
        "es una de las fuentes de información sociodemográfica más importante del", a("Sistema Estadístico Nacional (SEN)", href = "https://www.indec.gob.ar/indec/web/Institucional-Indec-SistemaEstadistico"), "Argentino.
              Si bien este operativo es más conocido por la Tasa de Desocupación",a("[1], ", href="#footnote-1"), "el abanico de indicadores que se pueden obtener para caracterizar las condiciones de vida de la población es muy amplio."
      ),
      
      p("Dos estrategias de análisis son plausible de abordar al momento de querer caracterizar a una población determinada. 
        La primera es el", strong("Análisis Transversal,"), "entendido como una forma de leer los datos en clave de 'foto'. Esta es el abordaje para el cual fue diseñada la encuesta, aunque no el único."
      ),
      
      p("Una segunda manera de interpretar la información es mediante el", strong("Anáisis Longitudinal"), "en el cual la lectura es en clave de 'película'. Esto es, para una misma población, observo su evolución respecto al indicador seleccionado.
      Para ejemplificar, bajo este análisis puedo saber si la población ocupada que entrevisté en el primer trimestre del 2023 se encuentra en la misma situación o la ha modificado (pasó a la desocupación o inactividad) en el trimestre siguiente"
      ),
      
      br(),
      h4("Análisis longitudinal de la EPH."),
      
      p("Esta forma de interpretar los datos se debe gracias al", strong("esquema de rotación "), "bajo el cual fue diseñada la muestra, conocido como '2-2-2'.
      Este esquema implica que una vivienda es seleccionada para ser entrevistada 4 veces. En una primera instancia participa del operativo durante los primeros", strong("dos "), "trimestres de forma consecutiva, descansa los", strong("dos "), "trimestres siguientes y vuelve a participar por", strong("dos "), "trimestres más, para finalmente salir de la muestra y no volver a ser seleccionada.
        
        Al usar un esquema como el descripto, la muestra plausible de ser utilizada para el análisis de panel (longitudinal) es (teóricamente) del 50% para trimestres consecutivos (ejemplo, trimestre 1 y 2 del 2022) y para un mismo trimestre de años consecutivo (trimestre 1 del año 2022 y 2023)"
      ),
      
      
      p(id="footnote-1", "1 Porcentaje entre la población desocupada y la población económicamente activa.")
    )
  ),
  nav_panel(
    icon = icon("camera-retro"),
    title = "Foto", 
    fluidRow(
      include_styles,
      filters, 
      # column(filter_sankey_anio_ant, width = 3),
      # column(filter_sankey_trim_ant, width = 3),
      # column(filter_sankey_categoria, width = 3),
      # column(filter_sankey_periodo_base, width = 3)
    ),
    layout_columns(
      col_widths = c(4,8),
      value_box(
        title = textOutput("pob"),
        value =  textOutput("pob_n"),
        showcase = bs_icon("activity"),
        p(textOutput("periodo"))
      ),
      
      card(
        autoWaiter(
          #html = waiting_screen, color = "black"
          color = "#405BFF"
        ),
        full_screen = TRUE,
        highchartOutput("sankey")
      )

    )
  ),
  nav_panel(
    icon = icon("video"),
    title = "Película",
    filters_line,
    div(
      style = "text-align: center; margin-bottom: 16px;",
      actionButton(
        "btn_pop",
        "¿Cómo se interpreta el dato?"
      ) |>
        popover(title = "Ejemplo de lectura",

                p("Si las opciones fijadas son:",
                  br(),
                  strong("Desde:"), "Desocupado",
                  br(),
                  strong("Hacia:"), "Ocupación",
                  br(),
                  "Y el panel en el eje x es", strong('2023_t1-t2'), ", la interpretación sería:",
                  br(),
                  br(),
                  em("Entre la población que se encontraba desocupada en el trimestre 1 del año 2023, el 44% pasó a la Ocupación para el trimestre 2 del mismo año")
                )
        )
    ),
    card(
      full_screen = TRUE,
      min_height = "520px",
      highchartOutput("line", height = "100%")
    )
  ),
  nav_spacer(),
  
  nav_menu(
    title = "+Info",
    align = "right",
    nav_item(a("Documento metodológico: La nueva EPH", href = "https://www.indec.gob.ar/ftp/cuadros/sociedad/metodologia_eph_continua.pdf")),
    nav_item(a("Paquete {eph}", href = "https://docs.ropensci.org/eph/")),
  ),
  nav_spacer(),
)


# Define server logic required to draw a histogram
server <- function(input, output, session) {

  ### Recalcula los duos trimestrales válidos cuando cambia el año.
  ### Si el duo previamente seleccionado sigue disponible, se preserva;
  ### si no, se cae al primer duo válido del año.
  observeEvent(input$anio_ant, {
    duos <- duos_disponibles_por_anio(input$anio_ant, periodos_disponibles)

    seleccion_actual <- isolate(input$trimestre_ant)
    seleccion_nueva <- if (!is.null(seleccion_actual) && seleccion_actual %in% duos) {
      seleccion_actual
    } else {
      duos[1]
    }

    updateSelectInput(
      session,
      "trimestre_ant",
      choices = duos,
      selected = seleccion_nueva
    )
  })

  shinyalert(
    title = "Buenas!",
    text = "Esta aplicación está en desarrollo. Si algo no está funcionando, se puede mejorar o incluso tenés una idea para agregar, podés escribirme a pablotiscornia@estacion-r.com",
    size = "s", 
    closeOnEsc = TRUE,
    closeOnClickOutside = FALSE,
    html = FALSE,
    type = "warning",
    showConfirmButton = TRUE,
    showCancelButton = FALSE,
    confirmButtonText = "JOYA",
    confirmButtonCol = "#405BFF",
    timer = 0,
    imageUrl = "",
    animation = TRUE
  )
  
  observe({
    
    anio_ant <- as.numeric(input$anio_ant)
    anio_post <- ifelse(as.numeric(input$trimestre_ant) %in% c(1:3), as.numeric(input$anio_ant), as.numeric(input$anio_ant) + 1)
    trim_ant <- as.numeric(input$trimestre_ant)
    trim_post <-ifelse(as.numeric(input$trimestre_ant) %in% c(1:3), as.numeric(input$trimestre_ant) + 1, 1)
    
    sentido <- input$periodo_base
    categoria_lab <- ifelse(input$category == "Ocupado", "Ocupación", 
                            ifelse(input$category == "Desocupado", "Desocupación","Inactividad"))
    
    output$pob <- renderText({
      paste("Población: ", ifelse(categoria_lab == "Ocupación", "Ocupada",
                                  ifelse(categoria_lab == "Desocupación", "Desocupada", "Inactiva")))
    })
    
    output$pob_n <- renderText({
      data <- read_parquet("data_output/df_tasas_mt.parquet") |> 
        filter(ANO4 == anio_ant & TRIMESTRE == trim_ant) |> 
        pull(ifelse(categoria_lab == "Ocupación", pob_ocupada,
                    ifelse(categoria_lab == "Desocupación", pob_desocupada, pob_inactiva)))
      
      format(data, big.mark = ".", decimal.mark = ",")
    })
    
    output$periodo <- renderText({
      paste("Año ", anio_ant, ", trimestre ", trim_ant)
    })
    
    ### Armo la base de panel
    df_eph_panel <- reactive({
      armo_base_panel(anio_0 = anio_ant, 
                      trimestre_0 = trim_ant,
                      anio_1 = anio_post, 
                      trimestre_1 = trim_post)
      
    })
    
    output$sankey <- renderHighchart({
      highcharter::hchart(
        object = armo_tabla_sankey(
          table = preparo_base(
            df = df_eph_panel(), 
            periodo_base = input$periodo_base), 
          categoria = input$category),
        "sankey", 
        name = ifelse(sentido == "t_anterior", 
                      glue::glue("Flujo desde la {categoria_lab}"),
                      glue::glue("Flujo hacia la {categoria_lab}"))
      ) |> 
        hc_title(text = "Flujo de la condición de actividad.") |> 
        hc_subtitle(text = glue(
          "Panel {ifelse(trim_ant %in% 1:3, paste0(anio_ant, ' - ', 'trimestre ', trim_ant, ' y ', trim_post), 
        paste0(anio_ant, ' - ', 'trimestre ', trim_ant, ' y ', anio_ant + 1, ' trimestre ', trim_post))}")) |> 
        hc_caption(text = "Fuente: Elaboración propia en base a la EPH-INDEC") |>
        hc_add_theme(hc_theme_estacion_r)
    })
    
    output$line <- renderHighchart({
      ### Índice 0-based del comienzo de la pandemia para plotBand (Highcharts
      ### usa categorías indexadas desde 0). Si "2020_t1-t2" no existe en la
      ### base por algún motivo, omitimos el plotBand.
      idx_pandemia_ini <- match("2020_t1-t2", levels(df_cond_act$periodo)) - 1
      idx_pandemia_fin <- match("2020_t3-t4", levels(df_cond_act$periodo)) - 1

      plot_bands <- if (!is.na(idx_pandemia_ini) && !is.na(idx_pandemia_fin)) {
        list(list(
          from = idx_pandemia_ini,
          to = idx_pandemia_fin,
          color = "rgba(234, 255, 56, 0.30)",
          label = list(
            text = "Pandemia COVID-19",
            style = list(color = "#191919", fontWeight = "600")
          )
        ))
      } else {
        list()
      }

      hchart(df_cond_act |>
               filter(from == input$desde, to %in% input$hacia) |>
               mutate(to = case_when(
                 from == "Desocupado_t0" & to == "Inactivo_t1" ~ "% de Desocupados que pasan a la Inactividad",
                 from == "Desocupado_t0" & to == "Desocupado_t1" ~ "% de Desocupados que siguen Desocupados",
                 from == "Desocupado_t0" & to == "Ocupado_t1" ~ "% de Desocupados que pasan a la Ocupación",
                 from == "Ocupado_t0" & to == "Inactivo_t1" ~ "% de Ocupados que pasan a la Inactividad",
                 from == "Ocupado_t0" & to == "Desocupado_t1" ~ "% de Ocupados que pasan a la Desocupación",
                 from == "Ocupado_t0" & to == "Ocupado_t1" ~ "% de Ocupados que siguen Ocupados",
                 from == "Inactivo_t0" & to == "Inactivo_t1" ~ "% de Inactivos que siguen Inactivos",
                 from == "Inactivo_t0" & to == "Desocupado_t1" ~ "% de Inactivos que pasan a la Desocupación",
                 from == "Inactivo_t0" & to == "Ocupado_t1" ~ "% de Inactivos que pasan a la Ocupación"),
                 id = stringr::str_replace_all(id, "tant", "t0"),
                 id = stringr::str_replace_all(id, "tpost", "t2")),
             "areaspline",
             hcaes(periodo, weight, group = to)) |>
        hc_add_theme(hc_theme_estacion_r) |>
        hc_chart(zoomType = "x") |>
        hc_plotOptions(
          areaspline = list(
            fillOpacity = 0.18,
            lineWidth = 2.5,
            marker = list(enabled = FALSE,
                          states = list(hover = list(enabled = TRUE, radius = 5)))
          )
        ) |>
        hc_xAxis(
          title = list(text = NULL),
          tickInterval = 4,
          plotBands = plot_bands,
          labels = list(rotation = -45, style = list(fontSize = "0.85em"))
        ) |>
        hc_yAxis(
          title = list(text = "% del total"),
          labels = list(format = "{value}%"),
          gridLineDashStyle = "Dot"
        ) |>
        hc_tooltip(
          shared = TRUE,
          useHTML = TRUE,
          headerFormat = "<span style='font-size: 0.9em; color: #191919;'><b>{point.key}</b></span><br/>",
          pointFormat = "<span style='color: {series.color}'>●</span> {series.name}: <b>{point.y}%</b><br/>",
          backgroundColor = "rgba(255,255,255,0.96)",
          borderColor = "#405BFF",
          borderRadius = 6
        ) |>
        hc_legend(align = "center", verticalAlign = "top", layout = "horizontal") |>
        hc_caption(
          text = "Elaboración propia en base a la EPH-INDEC. Arrastrá horizontalmente para hacer zoom."
        )
    })
    
  })
  # 
  # output$text <- renderPrint({
  #   trim_ant <- substr(last(df_cond_act$periodo), 7, 7)
  #   anio_ant <- substr(last(df_cond_act$periodo), 1, 4)
  #   trim_post <- substr(last(df_cond_act$periodo), 10, 10)
  #   anio_post <- substr(last(df_cond_act$periodo), 9, 12)
  #   
  #   dato <- df_cond_act |>
  #     filter(from == "Desocupado_t0", to == "Ocupado_t1", periodo == "2023_t1-t2") |>
  #     pull(weight)
  #   
  #   
  #   glue("> ¿Cómo se lee?: Ejemplo: Si el panel en el eje x es '2023_t1-t2', la interpretación sería: Entre la población que se encontraba desocupada en el trimestre {trim_ant} del año {anio_ant},
  #        el {dato}% pasó a la Ocupación para el trimestre {trim_post} del mismo año.")
  # })
}

# Run the application 
shinyApp(ui = ui, server = server)
