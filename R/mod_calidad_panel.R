### Módulo Shiny "Calidad de la muestra" (issue #36).
###
### Muestra el histórico del % de personas-panel encontradas (matched
### entre t0 y t1) sobre el total de la muestra del trimestre base, con
### filtros por rango de años y por tipo de dupla trimestral.
###
### Convención de nombres de dupla:
###   t1-t2, t2-t3, t3-t4 → consecutivas dentro del mismo año
###   t4-t1               → entre años contiguos (T4 año X → T1 año X+1)
###
### Datos: df_calidad_panel (cargado en ETL/01-extract.R desde
### data_output/calidad_panel_pct_historico.csv).


### Helper: deriva el código de dupla a partir de (trim_0, trim_1).
duo_label <- function(t0, t1) {
  paste0("t", t0, "-t", t1)
}


# UI -------------------------------------------------------------------------

mod_calidad_panel_ui <- function(id) {
  ns <- NS(id)

  ### Rango de años disponibles (puede estar vacío si el CSV no fue
  ### generado todavía; en ese caso el server muestra un mensaje).
  anios <- if (nrow(df_calidad_panel) > 0) {
    sort(unique(df_calidad_panel$anio_0))
  } else {
    integer(0)
  }
  anio_min <- if (length(anios)) min(anios) else 2003L
  anio_max <- if (length(anios)) max(anios) else 2025L

  ### Filtros NLQ siguiendo el patrón de los demás módulos.
  filtros <- filter_query(
    prefix_text = "",
    filter_preposition(
      "Mostrar el panel para los años",
      sliderInput(inputId = ns("anios"),
                  label = "Rango de años",
                  min   = anio_min,
                  max   = anio_max,
                  value = c(anio_min, anio_max),
                  step  = 1,
                  sep   = "",
                  ticks = FALSE,
                  width = "260px"),
      ""
    ),
    filter_preposition(
      "y la(s) dupla(s)",
      selectInput(inputId  = ns("duos"),
                  label    = "Tipo de dupla",
                  choices  = c("Todas"  = "todas",
                               "1 → 2"  = "t1-t2",
                               "2 → 3"  = "t2-t3",
                               "3 → 4"  = "t3-t4",
                               "4 → 1"  = "t4-t1"),
                  selected = "todas",
                  multiple = TRUE),
      ""
    ),
    suffix_text = ""
  )

  tagList(
    div(
      class = "calidad-intro",
      h3("Calidad de la muestra del panel"),
      p(
        "Para cada par de trimestres consecutivos (t0 → t1) se muestra el ",
        tags$strong("% de personas de la muestra de t0 que también aparecen en t1"),
        ". Por el esquema de rotación 2-2-2 de la EPH, el ",
        tags$strong("máximo teórico es 50%"),
        ": las otras dos rotaciones de la muestra del t0 no van a estar en t1 por diseño, no por atrición. Caídas por debajo de ese tope reflejan la calidad efectiva del operativo."
      )
    ),
    fluidRow(filtros),
    card(
      autoWaiter(color = "#405BFF"),
      full_screen = TRUE,
      min_height  = "520px",
      highchartOutput(ns("hc_calidad"), height = "100%")
    )
  )
}


# Server ---------------------------------------------------------------------

mod_calidad_panel_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    ### Filtra el histórico según rango de años y tipos de dupla.
    datos_filtrados <- reactive({
      req(nrow(df_calidad_panel) > 0)

      duos_sel <- input$duos %||% "todas"
      if ("todas" %in% duos_sel || length(duos_sel) == 0) {
        duos_sel <- c("t1-t2", "t2-t3", "t3-t4", "t4-t1")
      }

      anios_sel <- input$anios %||% c(min(df_calidad_panel$anio_0),
                                      max(df_calidad_panel$anio_0))

      df_calidad_panel |>
        mutate(duo = duo_label(trim_0, trim_1)) |>
        filter(anio_0 >= anios_sel[1],
               anio_0 <= anios_sel[2],
               duo %in% duos_sel) |>
        arrange(anio_0, trim_0) |>
        mutate(periodo = factor(periodo, levels = periodo))
    })

    output$hc_calidad <- renderHighchart({

      ### Caso edge: CSV no generado todavía.
      if (nrow(df_calidad_panel) == 0) {
        return(
          highchart() |>
            hc_title(text = "Datos no disponibles") |>
            hc_subtitle(text = paste(
              "Falta correr ETL/10-build_calidad_panel.R para generar",
              "data_output/calidad_panel_pct_historico.csv"
            )) |>
            hc_add_theme(hc_theme_estacion_r)
        )
      }

      df <- datos_filtrados()
      validate(need(nrow(df) > 0,
                    "No hay datos para los filtros seleccionados."))

      highchart() |>
        hc_chart(type = "column") |>
        hc_plotOptions(
          column = list(
            borderWidth  = 0,
            groupPadding = 0.05,
            pointPadding = 0.02
          )
        ) |>
        hc_xAxis(
          categories = as.character(df$periodo),
          title      = list(text = "Par trimestral (t0 → t1)"),
          labels     = list(rotation = -45,
                            step = max(1, ceiling(nrow(df) / 25)))
        ) |>
        hc_yAxis(
          title     = list(text = "% sobre la muestra del t0"),
          min       = 0,
          max       = 50,
          labels    = list(format = "{value}%"),
          plotLines = list(list(
            value     = 50,
            color     = "#191919",
            width     = 1,
            dashStyle = "Dash",
            zIndex    = 5,
            label     = list(
              text   = "Tope teórico 50% (esquema 2-2-2)",
              align  = "right",
              x      = -10,
              style  = list(color = "#191919", fontFamily = "Ubuntu",
                            fontSize = "0.8em")
            )
          ))
        ) |>
        hc_tooltip(
          headerFormat = "<b>{point.key}</b><br>",
          pointFormat  = paste0(
            "<span style=\"color:{series.color}\">●</span> ",
            "{series.name}: <b>{point.y}%</b>"
          )
        ) |>
        hc_add_series(
          name         = "Encontradas en panel",
          data         = df$pct_encontrado_n,
          color        = "#405BFF",
          showInLegend = FALSE
        ) |>
        hc_credits(enabled = FALSE) |>
        hc_add_theme(hc_theme_estacion_r)
    })
  })
}
