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
### En modo trimestral: "tN-tM" (ej "t1-t2"). En anual: "tN"
### (mismo trimestre entre años, ej "t1").
duo_label <- function(t0, t1, window = "trimestral") {
  if (window == "anual") {
    paste0("t", t0)
  } else {
    paste0("t", t0, "-t", t1)
  }
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
        ": las otras dos rotaciones de la muestra del t0 no van a estar en t1 por diseño, no por atrición. Caídas por debajo de ese tope reflejan la calidad efectiva del operativo. Más abajo: el ",
        tags$strong("% de paneles encontrados que vienen con inconsistencias"),
        " entre t0 y t1 (sexo distinto, edad imposible). Issue #37."
      )
    ),
    fluidRow(filtros),

    ### Tarjetas resumen sobre el rango filtrado: promedio del % encontrado
    ### + % de inconsistencias por tipo. Da el headline numérico antes del
    ### detalle por dúo en los charts.
    layout_columns(
      col_widths = c(3, 3, 3, 3),
      value_box(
        title = "Encontrado",
        value = textOutput(ns("kpi_encontrado")),
        showcase = bs_icon("search"),
        theme = "primary",
        p("del t0 aparece en t1"),
        p(em("máx. teórico 50%"),
          style = "font-size: 0.8em; opacity: 0.85; margin-top: 4px;")
      ),
      value_box(
        title = tagList(
          "Inconsistencias",
          bslib::popover(
            bsicons::bs_icon("info-circle",
                             style = "color: #405BFF; cursor: help; margin-left: 8px; font-size: 0.85em;"),
            "Personas matched entre t0 y t1 cuyo registro presenta inconsistencias detectadas por eph::organize_panels(): sexo distinto, edad fuera del rango esperado, etc.",
            placement = "right"
          )
        ),
        value = textOutput(ns("kpi_inc_total")),
        showcase = bs_icon("exclamation-triangle"),
        class = "value-box-bordered",
        p("del panel matched"),
        p(em("(suma de los tipos de abajo más otras señales)"),
          style = "font-size: 0.8em; opacity: 0.85; margin-top: 4px;")
      ),
      value_box(
        title = "Sexo distinto",
        value = textOutput(ns("kpi_inc_sexo")),
        showcase = bs_icon("gender-ambiguous"),
        class = "value-box-bordered",
        p("CH04 cambia entre t0 y t1"),
        p(em("debería ser invariante"),
          style = "font-size: 0.8em; opacity: 0.85; margin-top: 4px;")
      ),
      value_box(
        title = "Edad imposible",
        value = textOutput(ns("kpi_inc_edad")),
        showcase = bs_icon("calendar-x"),
        class = "value-box-bordered",
        p("CH06_t1 fuera de [CH06, CH06+1]"),
        p(em("baja o salta varios años"),
          style = "font-size: 0.8em; opacity: 0.85; margin-top: 4px;")
      )
    ),

    ### Chart 1: % encontrado por dúo (lo que había desde el inicio).
    card(
      card_header("% del panel encontrado, por dúo trimestral"),
      autoWaiter(color = "#405BFF"),
      full_screen = TRUE,
      min_height  = "440px",
      highchartOutput(ns("hc_calidad"), height = "100%")
    ),

    ### Chart 2: % de inconsistencia (total / sexo / edad) por dúo.
    ### Misma escala de tiempo que Chart 1 para comparar visualmente.
    card(
      card_header("% de paneles con inconsistencias, por dúo trimestral"),
      autoWaiter(color = "#405BFF"),
      full_screen = TRUE,
      min_height  = "440px",
      highchartOutput(ns("hc_inconsistencias"), height = "100%")
    )
  )
}


# Server ---------------------------------------------------------------------

mod_calidad_panel_server <- function(id, tipo_duo = shiny::reactive("trimestral")) {
  moduleServer(id, function(input, output, session) {

    ### Dataset según modo activo (issue #47).
    df_calidad_actual <- reactive({
      if (tipo_duo() == "anual") df_calidad_panel_anual else df_calidad_panel
    })

    ### Choices del selector "duos" según modo. En anual los dúos son
    ### tN (mismo trimestre entre años); en trimestral son tN-tM.
    observeEvent(tipo_duo(), {
      choices_nuevos <- if (tipo_duo() == "anual") {
        c("Todas" = "todas",
          "T1 vs T1" = "t1", "T2 vs T2" = "t2",
          "T3 vs T3" = "t3", "T4 vs T4" = "t4")
      } else {
        c("Todas"  = "todas",
          "1 → 2"  = "t1-t2", "2 → 3"  = "t2-t3",
          "3 → 4"  = "t3-t4", "4 → 1"  = "t4-t1")
      }
      updateSelectInput(session, "duos",
                        choices = choices_nuevos, selected = "todas")
    })

    ### Filtra el histórico según rango de años y tipos de dupla.
    datos_filtrados <- reactive({
      df_base <- df_calidad_actual()
      req(nrow(df_base) > 0)

      duos_sel <- input$duos %||% "todas"
      todos_los_duos <- if (tipo_duo() == "anual") {
        c("t1", "t2", "t3", "t4")
      } else {
        c("t1-t2", "t2-t3", "t3-t4", "t4-t1")
      }
      if ("todas" %in% duos_sel || length(duos_sel) == 0) {
        duos_sel <- todos_los_duos
      }

      anios_sel <- input$anios %||% c(min(df_base$anio_0),
                                      max(df_base$anio_0))

      df_base |>
        mutate(duo = duo_label(trim_0, trim_1, window = tipo_duo())) |>
        filter(anio_0 >= anios_sel[1],
               anio_0 <= anios_sel[2],
               duo %in% duos_sel) |>
        arrange(anio_0, trim_0) |>
        mutate(periodo = factor(periodo, levels = periodo))
    })

    ### KPIs resumen sobre el rango/dúos filtrados. Promedio simple de %
    ### entre los dúos seleccionados (no ponderado), suficiente para una
    ### lectura rápida del headline.
    output$kpi_encontrado <- renderText({
      df <- datos_filtrados()
      if (nrow(df) == 0) return("—")
      sprintf("%.1f%%", mean(df$pct_encontrado_n, na.rm = TRUE))
    })
    output$kpi_inc_total <- renderText({
      df <- datos_filtrados()
      if (nrow(df) == 0) return("—")
      sprintf("%.1f%%", mean(df$pct_inc_total, na.rm = TRUE))
    })
    output$kpi_inc_sexo <- renderText({
      df <- datos_filtrados()
      if (nrow(df) == 0) return("—")
      sprintf("%.1f%%", mean(df$pct_inc_sexo, na.rm = TRUE))
    })
    output$kpi_inc_edad <- renderText({
      df <- datos_filtrados()
      if (nrow(df) == 0) return("—")
      sprintf("%.1f%%", mean(df$pct_inc_edad, na.rm = TRUE))
    })

    output$hc_calidad <- renderHighchart({

      ### Caso edge: CSV no generado todavía para el modo activo.
      if (nrow(df_calidad_actual()) == 0) {
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

    ### Chart 2: % de inconsistencias por dúo trimestral. Tres series
    ### (total / sexo / edad) sobre el panel matched. Issue #37.
    output$hc_inconsistencias <- renderHighchart({
      if (nrow(df_calidad_actual()) == 0) {
        return(
          highchart() |>
            hc_title(text = "Datos no disponibles") |>
            hc_add_theme(hc_theme_estacion_r)
        )
      }

      df <- datos_filtrados()
      validate(need(nrow(df) > 0,
                    "No hay datos para los filtros seleccionados."))

      highchart() |>
        hc_chart(type = "line") |>
        hc_plotOptions(
          line = list(
            marker = list(enabled = FALSE,
                          states = list(hover = list(enabled = TRUE))),
            lineWidth = 2
          )
        ) |>
        hc_xAxis(
          categories = as.character(df$periodo),
          title      = list(text = "Par trimestral (t0 → t1)"),
          labels     = list(rotation = -45,
                            step = max(1, ceiling(nrow(df) / 25)))
        ) |>
        hc_yAxis(
          title  = list(text = "% sobre el panel matched"),
          min    = 0,
          labels = list(format = "{value}%")
        ) |>
        hc_tooltip(
          shared        = TRUE,
          headerFormat  = "<b>{point.key}</b><br>",
          pointFormat   = paste0(
            "<span style=\"color:{series.color}\">●</span> ",
            "{series.name}: <b>{point.y}%</b><br>"
          )
        ) |>
        hc_add_series(
          name  = "Total (flag eph)",
          data  = df$pct_inc_total,
          color = "#405BFF"
        ) |>
        hc_add_series(
          name  = "Edad imposible",
          data  = df$pct_inc_edad,
          color = "#1839F4",
          dashStyle = "ShortDash"
        ) |>
        hc_add_series(
          name  = "Sexo distinto",
          data  = df$pct_inc_sexo,
          color = "#191919",
          dashStyle = "Dot"
        ) |>
        hc_legend(
          align         = "center",
          verticalAlign = "top",
          layout        = "horizontal",
          itemStyle     = list(fontWeight = "500", fontFamily = "Ubuntu")
        ) |>
        hc_caption(text = paste(
          "Total: flag `consistencia` de eph::organize_panels (incluye otras señales).",
          "Edad: CH06_t1 fuera del rango [CH06, CH06+1].",
          "Sexo: CH04 distinto entre t0 y t1."
        )) |>
        hc_credits(enabled = FALSE) |>
        hc_add_theme(hc_theme_estacion_r)
    })

    ### Issue #74: mantener outputs vivos cuando el módulo vive dentro de un
    ### conditionalPanel (hub-and-spoke). El JS de reflow se encarga del
    ### resize tras volver a la vista. Aplicamos desde onFlushed por si los
    ### outputs aún no están registrados al setup del moduleServer.
    session$onFlushed(function() {
      for (n in c("hc_calidad", "hc_inconsistencias")) {
        tryCatch(
          outputOptions(output, n, suspendWhenHidden = FALSE),
          error = function(e) NULL
        )
      }
    }, once = TRUE)
  })
}
