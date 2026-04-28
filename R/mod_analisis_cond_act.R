### Módulo Shiny para el análisis "Condición de actividad" de la EPH.
###
### Encapsula la pestaña Foto (Sankey de flujo entre Ocupado/Desocupado/
### Inactivo en un panel trimestral) + Película (línea histórica del flujo
### con filtros NLQ por dúo trimestral).
###
### En Fase 1 del epic #6 este módulo es ESPECÍFICO de "condición de
### actividad". En Fase 3 se generalizará para reusarlo en otros análisis
### (movilidad ocupacional, formalidad).


# UI del módulo --------------------------------------------------------------

mod_cond_act_ui <- function(id) {
  ns <- NS(id)

  ### Filtros NLQ del Sankey ("Foto"). Se construyen acá para que los IDs
  ### queden namespaced bajo el módulo.
  filtros_foto <- filter_query(
    prefix_text = "",
    filter_preposition(
      "Conocer el",
      selectInput(inputId = ns("periodo_base"),
                  label = "Sentido (trimestre base)",
                  choices = c("destino" = "t_anterior",
                              "origen" = "t_posterior")),
      ""
    ),
    filter_preposition(
      "de los",
      selectInput(inputId = ns("category"),
                  label = "Categoría de base (el 100%)",
                  choices = c("Ocupados" = "Ocupado",
                              "Desocupados" = "Desocupado",
                              "Inactivos" = "Inactivo")),
      ""
    ),
    filter_preposition(
      "para el año",
      selectInput(inputId = ns("anio_ant"),
                  label = "Año del panel",
                  choices = anios_disponibles,
                  selected = anio_max_disponible),
      ""
    ),
    filter_preposition(
      "entre los trimestres",
      selectInput(inputId = ns("trimestre_ant"),
                  label = "Panel (trimestres consecutivos)",
                  choices = c("1-2" = 1, "2-3" = 2, "3-4" = 3, "4-1" = 4),
                  selected = 1),
      ""
    ),
    suffix_text = ""
  )

  ### Filtros NLQ de la serie histórica ("Película").
  filtros_pelicula <- filter_query(
    prefix_text = "",
    filter_preposition(
      "Mostrar el flujo desde la",
      selectInput(inputId = ns("desde"),
                  label = "Desde",
                  choices = c("Ocupación" = "Ocupado_t0",
                              "Desocupación" = "Desocupado_t0",
                              "Inactividad" = "Inactivo_t0"),
                  selected = "Desocupado_t0"),
      ""
    ),
    filter_preposition(
      "hacia",
      selectInput(inputId = ns("hacia"),
                  label = "Hacia",
                  choices = c("Ocupación" = "Ocupado_t1",
                              "Desocupación" = "Desocupado_t1",
                              "Inactividad" = "Inactivo_t1"),
                  selected = "Ocupado_t1",
                  multiple = TRUE),
      ""
    ),
    filter_preposition(
      "en los trimestres",
      selectInput(inputId = ns("duo"),
                  label = "Trimestres",
                  choices = c("Todos los trimestres" = "todos",
                              "1-2" = "t1-t2",
                              "2-3" = "t2-t3",
                              "3-4" = "t3-t4",
                              "4-1" = "t4-t1"),
                  selected = "todos"),
      ""
    ),
    suffix_text = ""
  )

  ### UI completa del análisis con dos sub-tabs Foto / Película.
  bslib::navset_card_tab(
    bslib::nav_panel(
      title = "Foto",
      icon = icon("camera-retro"),
      fluidRow(filtros_foto),
      layout_columns(
        col_widths = c(4, 8),
        value_box(
          title = textOutput(ns("pob")),
          value = textOutput(ns("pob_n")),
          showcase = bs_icon("activity"),
          p(textOutput(ns("periodo")))
        ),
        card(
          autoWaiter(color = "#405BFF"),
          full_screen = TRUE,
          highchartOutput(ns("sankey"))
        )
      )
    ),
    bslib::nav_panel(
      title = "Película",
      icon = icon("video"),
      filtros_pelicula,
      div(
        style = "text-align: center; margin-bottom: 16px;",
        actionButton(ns("btn_pop"), "¿Cómo se interpreta el dato?") |>
          popover(
            title = "Ejemplo de lectura",
            p("Si las opciones fijadas son:",
              br(),
              strong("Desde:"), "Desocupado",
              br(),
              strong("Hacia:"), "Ocupación",
              br(),
              "Y el panel en el eje x es", strong("2023_t1-t2"),
              ", la interpretación sería:",
              br(), br(),
              em("Entre la población que se encontraba desocupada en el trimestre 1 del año 2023, el 44% pasó a la Ocupación para el trimestre 2 del mismo año"))
          )
      ),
      card(
        full_screen = TRUE,
        min_height = "520px",
        highchartOutput(ns("line"), height = "100%")
      )
    )
  )
}


# Server del módulo ----------------------------------------------------------

mod_cond_act_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    ### Recalcula los duos trimestrales válidos cuando cambia el año del
    ### panel. Si el duo previamente seleccionado sigue disponible, se
    ### preserva; si no, se cae al primer duo válido del año.
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

    observe({

      anio_ant <- as.numeric(input$anio_ant)
      anio_post <- ifelse(as.numeric(input$trimestre_ant) %in% c(1:3),
                          as.numeric(input$anio_ant),
                          as.numeric(input$anio_ant) + 1)
      trim_ant <- as.numeric(input$trimestre_ant)
      trim_post <- ifelse(as.numeric(input$trimestre_ant) %in% c(1:3),
                          as.numeric(input$trimestre_ant) + 1, 1)

      sentido <- input$periodo_base
      categoria_lab <- ifelse(input$category == "Ocupado", "Ocupación",
                              ifelse(input$category == "Desocupado", "Desocupación",
                                     "Inactividad"))

      output$pob <- renderText({
        paste("Población: ",
              ifelse(categoria_lab == "Ocupación", "Ocupada",
                     ifelse(categoria_lab == "Desocupación", "Desocupada",
                            "Inactiva")))
      })

      output$pob_n <- renderText({
        data <- read_parquet("data_output/df_tasas_mt.parquet") |>
          filter(ANO4 == anio_ant & TRIMESTRE == trim_ant) |>
          pull(ifelse(categoria_lab == "Ocupación", pob_ocupada,
                      ifelse(categoria_lab == "Desocupación", pob_desocupada,
                             pob_inactiva)))

        format(data, big.mark = ".", decimal.mark = ",")
      })

      output$periodo <- renderText({
        paste("Año ", anio_ant, ", trimestre ", trim_ant)
      })

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
        ### El plotBand de pandemia solo tiene sentido cuando se ven todos
        ### los duos (los índices 0-based se calculan sobre la serie
        ### completa). Si se filtra a un dúo específico (peras con peras),
        ### lo omitimos.
        mostrar_pandemia <- input$duo == "todos"
        idx_pandemia_ini <- match("2020_t1-t2", levels(df_cond_act$periodo)) - 1
        idx_pandemia_fin <- match("2020_t3-t4", levels(df_cond_act$periodo)) - 1

        plot_bands <- if (mostrar_pandemia &&
                          !is.na(idx_pandemia_ini) &&
                          !is.na(idx_pandemia_fin)) {
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

        ### tickInterval: con todos los duos hay ~80 puntos (cada 4).
        ### Filtrando por dúo específico hay ~22 puntos (uno por año), todas.
        tick_interval <- if (input$duo == "todos") 4 else 1

        ### Pre-calcula flags de extremos por serie para el dataLabels filter.
        ### Highcharts usa el atributo isExtremo de cada punto vía
        ### dataLabels.filter (property == TRUE) para mostrar la etiqueta
        ### solo en max y min de cada grupo.
        df_data <- df_cond_act |>
          filter(from == input$desde, to %in% input$hacia) |>
          filter(input$duo == "todos" |
                   stringr::str_ends(as.character(periodo), input$duo)) |>
          arrange(periodo) |>
          mutate(to = case_when(
            from == "Desocupado_t0" & to == "Inactivo_t1"  ~ "% de Desocupados que pasan a la Inactividad",
            from == "Desocupado_t0" & to == "Desocupado_t1" ~ "% de Desocupados que siguen Desocupados",
            from == "Desocupado_t0" & to == "Ocupado_t1"   ~ "% de Desocupados que pasan a la Ocupación",
            from == "Ocupado_t0"    & to == "Inactivo_t1"  ~ "% de Ocupados que pasan a la Inactividad",
            from == "Ocupado_t0"    & to == "Desocupado_t1" ~ "% de Ocupados que pasan a la Desocupación",
            from == "Ocupado_t0"    & to == "Ocupado_t1"   ~ "% de Ocupados que siguen Ocupados",
            from == "Inactivo_t0"   & to == "Inactivo_t1"  ~ "% de Inactivos que siguen Inactivos",
            from == "Inactivo_t0"   & to == "Desocupado_t1" ~ "% de Inactivos que pasan a la Desocupación",
            from == "Inactivo_t0"   & to == "Ocupado_t1"   ~ "% de Inactivos que pasan a la Ocupación"),
            id = stringr::str_replace_all(id, "tant", "t0"),
            id = stringr::str_replace_all(id, "tpost", "t2")) |>
          mutate(isExtremo = (weight == max(weight, na.rm = TRUE)) |
                              (weight == min(weight, na.rm = TRUE)),
                 .by = to)

        hchart(df_data, "areaspline",
               hcaes(periodo, weight, group = to)) |>
          hc_add_theme(hc_theme_estacion_r) |>
          hc_chart(zoomType = "x") |>
          hc_plotOptions(
            areaspline = list(
              fillOpacity = 0.18,
              lineWidth = 2.5,
              marker = list(enabled = FALSE,
                            states = list(hover = list(enabled = TRUE, radius = 5))),
              dataLabels = list(
                enabled = TRUE,
                filter = list(property = "isExtremo", operator = "==", value = TRUE),
                format = "{point.y}%",
                style = list(fontSize = "0.75em",
                             textOutline = "2px white",
                             color = "#191919",
                             fontWeight = "600")
              )
            )
          ) |>
          hc_xAxis(
            title = list(text = NULL),
            tickInterval = tick_interval,
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
          hc_legend(
          align = "center", verticalAlign = "top", layout = "horizontal",
          itemStyle = list(cursor = "pointer", fontWeight = "500")
        ) |>
          hc_caption(
            text = "Elaboración propia en base a la EPH-INDEC. Arrastrá horizontalmente para hacer zoom · Click en una serie para mostrarla u ocultarla."
          )
      })

    })
  })
}
