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

      ### Tarjetas con tasas destacadas (issue #16 · opción B).
      layout_columns(
        col_widths = c(4, 4, 4),
        value_box(
          title = "Persistencia",
          value = textOutput(ns("tasa_persistencia")),
          showcase = bs_icon("arrow-repeat"),
          p("siguen en su categoría")
        ),
        value_box(
          title = "Salida",
          value = textOutput(ns("tasa_salida")),
          showcase = bs_icon("box-arrow-right"),
          theme = "secondary",
          p("cambiaron a otra categoría")
        ),
        value_box(
          title = "Entrada",
          value = textOutput(ns("tasa_entrada")),
          showcase = bs_icon("box-arrow-in-left"),
          theme = "secondary",
          p("vinieron de otra categoría")
        )
      ),

      ### Sankey + matriz de transición (issue #16 · opción A).
      ### Proporción 5/7: matriz lado derecho con más espacio para que la
      ### tabla NxN se vea completa sin scroll horizontal (issue #19).
      layout_columns(
        col_widths = c(5, 7),
        card(
          autoWaiter(color = "#405BFF"),
          full_screen = TRUE,
          highchartOutput(ns("sankey"))
        ),
        card(
          card_header("Matriz de transición"),
          gt::gt_output(ns("matriz_transicion"))
        )
      ),

      ### Value box compacto con la población base (lo que era el principal).
      layout_columns(
        col_widths = c(4, 8),
        value_box(
          title = textOutput(ns("pob")),
          value = textOutput(ns("pob_n")),
          showcase = bs_icon("activity"),
          p(textOutput(ns("periodo")))
        ),
        card(
          card_body(
            p(em("Tip:"), "Pasá el mouse sobre el Sankey o la matriz para ver porcentajes precisos. Las tarjetas de arriba se calculan respecto a la categoría seleccionada en el filtro.")
          )
        )
      )
    ),
    bslib::nav_panel(
      title = "Comparar",
      icon = icon("layer-group"),
      filter_query(
        prefix_text = "",
        filter_preposition(
          "Comparar el",
          selectInput(inputId = ns("comp_periodo_base"),
                      label = "Sentido",
                      choices = c("destino" = "t_anterior",
                                  "origen" = "t_posterior")),
          ""
        ),
        filter_preposition(
          "de los",
          selectInput(inputId = ns("comp_category"),
                      label = "Categoría",
                      choices = c("Ocupados" = "Ocupado",
                                  "Desocupados" = "Desocupado",
                                  "Inactivos" = "Inactivo")),
          ""
        ),
        filter_preposition(
          "entre",
          selectInput(inputId = ns("comp_anio_a"),
                      label = "Año A",
                      choices = anios_disponibles,
                      selected = max(anios_disponibles) - 5),
          "y"
        ),
        filter_preposition(
          "",
          selectInput(inputId = ns("comp_anio_b"),
                      label = "Año B",
                      choices = anios_disponibles,
                      selected = anio_max_disponible),
          ""
        ),
        filter_preposition(
          "en los trimestres",
          selectInput(inputId = ns("comp_trimestre"),
                      label = "Panel",
                      choices = c("1-2" = 1, "2-3" = 2, "3-4" = 3, "4-1" = 4),
                      selected = 1),
          ""
        ),
        suffix_text = ""
      ),

      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header(textOutput(ns("comp_header_a"))),
          autoWaiter(color = "#405BFF"),
          full_screen = TRUE,
          highchartOutput(ns("sankey_a"))
        ),
        card(
          card_header(textOutput(ns("comp_header_b"))),
          autoWaiter(color = "#EAFF38"),
          full_screen = TRUE,
          highchartOutput(ns("sankey_b"))
        )
      ),

      div(
        style = "padding: 0 1rem 1rem;",
        p(em("Tip:"), "Usá la comparación para mirar el mismo dúo trimestral en dos años distintos (ej: pre vs post pandemia) y entender cómo cambió la dinámica de movilidad.")
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

      ### Tarjetas con tasas destacadas (issue #16 · opción B).
      tasas <- reactive({
        arma_tasas_destacadas(
          df_panel = df_eph_panel(),
          var = "ESTADO",
          etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
          categoria = input$category
        )
      })
      output$tasa_persistencia <- renderText({ paste0(tasas()$persistencia, "%") })
      output$tasa_salida       <- renderText({ paste0(tasas()$salida, "%") })
      output$tasa_entrada      <- renderText({ paste0(tasas()$entrada, "%") })

      ### Matriz de transición (issue #16 · opción A).
      output$matriz_transicion <- gt::render_gt({
        matriz <- arma_matriz_transicion(
          df_panel = df_eph_panel(),
          var = "ESTADO",
          etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar")
        )
        arma_matriz_transicion_gt(matriz, titulo = NULL)
      })

      ### Comparar paneles (issue #16 · opción C). Renderiza 2 Sankey
      ### lado a lado para el mismo dúo trimestral en años distintos.
      arma_sankey_comparativo <- function(anio_panel, anio_label) {
        anio <- as.numeric(anio_panel)
        trim <- as.numeric(input$comp_trimestre)
        anio_post <- if (trim %in% 1:3) anio else anio + 1
        trim_post <- if (trim %in% 1:3) trim + 1 else 1

        df_p <- armo_base_panel(anio_0 = anio, trimestre_0 = trim,
                                anio_1 = anio_post, trimestre_1 = trim_post)

        categoria_lab <- ifelse(input$comp_category == "Ocupado", "Ocupación",
                                ifelse(input$comp_category == "Desocupado",
                                       "Desocupación", "Inactividad"))
        sentido_label <- if (input$comp_periodo_base == "t_anterior") {
          glue::glue("Flujo desde la {categoria_lab}")
        } else {
          glue::glue("Flujo hacia la {categoria_lab}")
        }

        highcharter::hchart(
          armo_tabla_sankey(
            preparo_base(df_p, periodo_base = input$comp_periodo_base),
            categoria = input$comp_category),
          "sankey", name = sentido_label
        ) |>
          hc_subtitle(text = glue::glue("Panel {anio} - trimestre {trim} y {trim_post}")) |>
          hc_add_theme(hc_theme_estacion_r)
      }

      output$comp_header_a <- renderText({
        paste("Panel A · Año", input$comp_anio_a)
      })
      output$comp_header_b <- renderText({
        paste("Panel B · Año", input$comp_anio_b)
      })
      output$sankey_a <- renderHighchart({
        arma_sankey_comparativo(input$comp_anio_a, "A")
      })
      output$sankey_b <- renderHighchart({
        arma_sankey_comparativo(input$comp_anio_b, "B")
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

        arma_line_chart_areaspline(
          df_data = df_data,
          levels_periodo = levels(df_cond_act$periodo),
          mostrar_pandemia = input$duo == "todos",
          tick_interval = if (input$duo == "todos") 4 else 1,
          caption_text = "Elaboración propia en base a la EPH-INDEC. Arrastrá horizontalmente para hacer zoom · Click en una serie para mostrarla u ocultarla."
        )
      })

    })
  })
}
