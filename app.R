### Orden de carga:
###   00-libraries → paquetes
###   99-functions → lógica de negocio (necesita libs cargadas)
###   01-extract   → carga datos en memoria (df_eph_full, df_cond_act, df_tasas_mt)
###   02-transform → componentes UI (necesita los datos cargados)
source("ETL/00-libraries.R")
source("ETL/99-functions.R")
source("ETL/01-extract.R")
source("ETL/02-transform.R")

library(shinyalert)

waiting_screen <- tagList(
  spin_flower(),
  h4("Bancame un toque...")
)

options(shiny.useragg = TRUE)
thematic_shiny(font = "auto")

# Define UI for application that draws a histogram
ui <- page_navbar(
  
  # Tema oficial Estación R
  # Ref: Proyectos/_activos/identidad_visual/GUIA_DE_ESTILO.md
  theme = bslib::bs_theme(
    version      = 5,
    bg           = "#FFFFFF",
    fg           = "#191919",
    primary      = "#405BFF",
    secondary    = "#EAFF38",
    base_font    = bslib::font_google("Ubuntu"),
    heading_font = bslib::font_google("Ubuntu", wght = c(400, 500, 700)),
    font_scale   = 1
  ),
  
  
  # ##-- Logo ----
  # list(tags$head(HTML('<link rel="icon", href="img/logo.png",
  #                       type="image/png" />'))),
  # 
  # div(style="padding: 1px 0px; width: '100%'",
  #     titlePanel(
  #       title="", windowTitle = "estacion-r"
  #     )
  # ),
  
  useWaitress(color = "#7F7FFF"),
  
  title = div(tags$a(href='https://linktr.ee/estacion_r',
             tags$img(src='https://pbs.twimg.com/profile_banners/1214735980172845056/1716430021/600x200',
                      height = 50, width = 150)), align = "left"),
  #bg = "white",
  underline = TRUE,
  
  nav_panel(
    icon = icon("circle-info"),
    title = "Sobre la App", 
    card(
      class = "bg-dark",
      #padding = "20px", gap = "20px",
      
      
      br(),
      
      titlePanel(title=div(tags$a(href='https://linktr.ee/estacion_r',
                                  tags$img(src='https://pbs.twimg.com/profile_banners/1214735980172845056/1716430021/600x200',
                                           height = 105, width = 300)), align = "center")),
      
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
    fluidRow(
      column(filter_line_desde, width = 3),
      column(filter_line_hacia, width = 3),
     
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
      #card_header("Flujo de la Condición de Actividad - PELÍCULA"),
      # !!!filters_line,
      highchartOutput("line"),
      #plotOutput("line"),
      mainPanel(
        
        
        #textOutput("text")
      )
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
server <- function(input, output) {
  
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
        hc_add_theme(hc_theme_smpl())
    })
    
    output$line <- renderHighchart({
      hchart(df_cond_act |> 
               filter(from == input$desde, to %in% input$hacia) |> 
               mutate(to = case_when(
                 from == "Desocupado_t0" & to == "Inactivo_t1" ~ "% de Desocupados que pasan a la Inactividad:",
                 from == "Desocupado_t0" & to == "Desocupado_t1" ~ "% de Desocupados que pasan a la Desocupación:",
                 from == "Desocupado_t0" & to == "Ocupado_t1" ~ "% de Desocupados que pasan a la Ocupación:",
                 from == "Ocupado_t0" & to == "Inactivo_t1" ~ "% de Ocupados que pasan a la Inactividad:",
                 from == "Ocupado_t0" & to == "Desocupado_t1" ~ "% de Ocupados que pasan a la Desocupación:",
                 from == "Ocupado_t0" & to == "Ocupado_t1" ~ "% de Ocupados que pasan a la Ocupación:",
                 from == "Inactivo_t0" & to == "Inactivo_t1" ~ "% de Inactivos que pasan a la Inactividad:",
                 from == "Inactivo_t0" & to == "Desocupado_t1" ~ "% de Inactivos que pasan a la Desocupación:",
                 from == "Inactivo_t0" & to == "Ocupado_t1" ~ "% de Inactivos que pasan a la Ocupación:"),
                 id = stringr::str_replace_all(id, "tant", "t0"),
                 id = stringr::str_replace_all(id, "tpost", "t2")),
             "line", 
             hcaes(periodo, weight, group = to)) |> 
        hc_add_theme(hc_theme_smpl()) |> 
        hc_tooltip(
          pointFormat = "<span  style='color: {series.color}'> {series.name} <b>{point.y}</b><br/></span>",
          shadow = TRUE,
          backgroundColor = "white",
          style = list(textOutline = "3px #00000"),
          borderColor = "red",
          borderWidth = 0
        ) |> 
        hc_annotations(
          list(
            labelOptions = list(
              shape = "connector",
              align = "right",
              justify = FALSE,
              crop = TRUE,
              style = list(fontSize = "0.8em", textOutline = "1px white")
            ),
            labels = list(
              list(point = list(x = 11, y = 40, xAxis = 0, yAxis = 0), 
                   text = "Comienzo de la Pandemia")
            )
          )
        )|>  
        hc_caption(
          text = "Elaboración propia en base a la EPH-INDEC."
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
