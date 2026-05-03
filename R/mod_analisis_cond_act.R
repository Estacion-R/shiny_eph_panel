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
  bslib::navset_card_underline(
    bslib::nav_panel(
      title = "Foto",
      icon = icon("camera-retro"),
      fluidRow(filtros_foto),
      uiOutput(ns("alert_int_foto")),

      ### Cuatro tarjetas destacadas: población base + 3 tasas (issues
      ### #16 + #21 + #34). Población va primera porque define el "100%"
      ### sobre el cual se calculan las tasas de la derecha. Persistencia
      ### es el dato principal de movilidad, va en azul primario;
      ### Salida/Entrada son los dos contracampos.
      layout_columns(
        col_widths = c(3, 3, 3, 3),
        value_box(
          title = tagList(
            textOutput(ns("pob"), inline = TRUE),
            bslib::popover(
              bsicons::bs_icon("info-circle",
                               style = "color: #405BFF; cursor: help; margin-left: 8px; font-size: 0.85em;"),
              "Pasá el mouse sobre el Sankey o la matriz para ver porcentajes precisos. Las tarjetas de la derecha se calculan respecto a esta población.",
              placement = "right"
            )
          ),
          value = textOutput(ns("pob_n")),
          showcase = bs_icon("activity"),
          class = "value-box-bordered",
          p(textOutput(ns("periodo")))
        ),
        value_box(
          title = "Persistencia",
          value = textOutput(ns("tasa_persistencia")),
          showcase = bs_icon("arrow-repeat"),
          theme = "primary",
          p("siguen en su categoría"),
          p(textOutput(ns("delta_persistencia")),
            style = "font-size: 0.8em; opacity: 0.85; margin-top: 4px;")
        ),
        value_box(
          title = "Salida",
          value = textOutput(ns("tasa_salida")),
          showcase = bs_icon("box-arrow-right"),
          class = "value-box-bordered",
          p("cambiaron a otra categoría"),
          p(textOutput(ns("delta_salida")),
            style = "font-size: 0.8em; opacity: 0.85; margin-top: 4px;")
        ),
        value_box(
          title = "Entrada",
          value = textOutput(ns("tasa_entrada")),
          showcase = bs_icon("box-arrow-in-left"),
          class = "value-box-bordered",
          p("vinieron de otra categoría"),
          p(textOutput(ns("delta_entrada")),
            style = "font-size: 0.8em; opacity: 0.85; margin-top: 4px;")
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
      )
    ),
    bslib::nav_panel(
      title = "Película",
      icon = icon("video"),
      uiOutput(ns("aviso_anual_pelicula")),
      filtros_pelicula,
      div(
        style = "text-align: center; margin: 4px 0 12px 0;",
        checkboxInput(ns("excluir_int_pelicula"),
                      label = "Excluir período de intervención INDEC (2007-2015)",
                      value = FALSE)
      ),
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
    ),

    bslib::nav_panel(
      title = "Tasas",
      icon = icon("chart-line"),
      uiOutput(ns("aviso_anual_tasas")),
      filter_query(
        prefix_text = "",
        filter_preposition(
          "Mostrar la",
          selectInput(inputId = ns("tasas_tipo"),
                      label = "Tipo de tasa",
                      choices = c("Persistencia" = "Persistencia",
                                  "Salida" = "Salida",
                                  "Entrada" = "Entrada"),
                      selected = "Persistencia",
                      multiple = TRUE),
          "para los"
        ),
        filter_preposition(
          "",
          selectInput(inputId = ns("tasas_category"),
                      label = "Categoría",
                      choices = c("Ocupados" = "Ocupado",
                                  "Desocupados" = "Desocupado",
                                  "Inactivos" = "Inactivo"),
                      selected = "Ocupado"),
          ""
        ),
        filter_preposition(
          "en los trimestres",
          selectInput(inputId = ns("tasas_duo"),
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
      ),
      div(
        style = "text-align: center; margin: 4px 0 12px 0;",
        checkboxInput(ns("excluir_int_tasas"),
                      label = "Excluir período de intervención INDEC (2007-2015)",
                      value = FALSE)
      ),
      card(
        full_screen = TRUE,
        min_height = "520px",
        highchartOutput(ns("tasas_chart"), height = "100%")
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

      uiOutput(ns("alert_int_comparar")),

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

      ### Nota explicativa colapsada en popover sobre info-circle
      ### (issue #34). Anclada al pie del tab Comparar.
      div(
        style = "text-align: center; padding: 0.5rem 0;",
        bslib::popover(
          tags$span(
            bsicons::bs_icon("info-circle",
                             style = "color: #405BFF; cursor: help; margin-right: 6px;"),
            tags$small(style = "color: #405BFF; cursor: help;",
                       "¿Cómo se interpreta esta comparación?")
          ),
          "Usá la comparación para mirar el mismo dúo trimestral en dos años distintos (ej: pre vs post pandemia) y entender cómo cambió la dinámica de movilidad.",
          placement = "top"
        )
      )
    )
  )
}


# Server del módulo ----------------------------------------------------------

mod_cond_act_server <- function(id, tipo_duo = shiny::reactive("trimestral")) {
  moduleServer(id, function(input, output, session) {

    ### Periodos / años válidos según el modo activo (issue #44).
    ### En modo trimestral usamos el set completo del panel intertrim.
    ### En modo anual restringimos a los dúos donde existe (anio_0+1, trim_0)
    ### en el microdato (que es lo que pre-computa ETL/09b).
    periodos_actuales <- reactive({
      if (tipo_duo() == "anual") periodos_disponibles_anual
      else periodos_disponibles
    })
    anios_actuales <- reactive({
      if (tipo_duo() == "anual") anios_disponibles_anual
      else anios_disponibles
    })

    ### Cuando cambia el modo, actualizar el selector de año para limitar
    ### a los años válidos. Si el año actual sigue siendo válido se
    ### preserva; si no, fallback al máximo año disponible.
    observeEvent(tipo_duo(), {
      anios <- anios_actuales()
      if (length(anios) == 0) return()

      sel_actual <- isolate(input$anio_ant)
      sel_nueva <- if (!is.null(sel_actual) &&
                       as.numeric(sel_actual) %in% anios) {
        sel_actual
      } else {
        max(anios)
      }

      updateSelectInput(session, "anio_ant",
                        choices = anios, selected = sel_nueva)
    })

    ### Recalcula los duos trimestrales válidos cuando cambia el año o
    ### el modo del dúo. Si el duo previamente seleccionado sigue
    ### disponible, se preserva; si no, se cae al primer duo válido.
    observe({
      anio <- input$anio_ant
      modo <- tipo_duo()
      req(anio)

      duos <- duos_disponibles_por_anio(anio, periodos_actuales(),
                                        window = modo)
      if (length(duos) == 0) return()

      seleccion_actual <- isolate(input$trimestre_ant)
      seleccion_nueva <- if (!is.null(seleccion_actual) &&
                             seleccion_actual %in% duos) {
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
                        trimestre_1 = trim_post,
                        window = tipo_duo())
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

      ### Tasas del mismo dúo trimestral del año anterior (issue #21).
      ### NULL si no hay datos del año anterior (ej: estamos en el primer
      ### año del histórico).
      tasas_anio_ant <- reactive({
        anio_prev <- anio_ant - 1
        if (anio_prev < min(anios_disponibles)) return(NULL)
        ### Verificar que existan ambos extremos del panel del año anterior.
        anio_post_prev <- anio_post - 1
        existe <- paste(anio_prev, trim_ant) %in%
                    paste(periodos_disponibles$ANO4, periodos_disponibles$TRIMESTRE) &&
                  paste(anio_post_prev, trim_post) %in%
                    paste(periodos_disponibles$ANO4, periodos_disponibles$TRIMESTRE)
        if (!existe) return(NULL)
        df_prev <- armo_base_panel(
          anio_0 = anio_prev, trimestre_0 = trim_ant,
          anio_1 = anio_post_prev, trimestre_1 = trim_post,
          window = tipo_duo()
        )
        arma_tasas_destacadas(
          df_panel = df_prev, var = "ESTADO",
          etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
          categoria = input$category
        )
      })

      delta_label <- reactive({
        anio_prev <- anio_ant - 1
        glue::glue("vs {anio_prev} T{trim_ant}-T{trim_post}")
      })

      output$tasa_persistencia <- renderText({ paste0(tasas()$persistencia, "%") })
      output$tasa_salida       <- renderText({ paste0(tasas()$salida, "%") })
      output$tasa_entrada      <- renderText({ paste0(tasas()$entrada, "%") })

      output$delta_persistencia <- renderText({
        ant <- tasas_anio_ant()
        if (is.null(ant)) return("sin comparación previa")
        paste(formato_delta(tasas()$persistencia - ant$persistencia), delta_label())
      })
      output$delta_salida <- renderText({
        ant <- tasas_anio_ant()
        if (is.null(ant)) return("sin comparación previa")
        paste(formato_delta(tasas()$salida - ant$salida), delta_label())
      })
      output$delta_entrada <- renderText({
        ant <- tasas_anio_ant()
        if (is.null(ant)) return("sin comparación previa")
        paste(formato_delta(tasas()$entrada - ant$entrada), delta_label())
      })

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
                                anio_1 = anio_post, trimestre_1 = trim_post,
                                window = tipo_duo())

        categoria_lab <- ifelse(input$comp_category == "Ocupado", "Ocupación",
                                ifelse(input$comp_category == "Desocupado",
                                       "Desocupación", "Inactividad"))
        sentido_label <- if (input$comp_periodo_base == "t_anterior") {
          glue::glue("Flujo desde la {categoria_lab}")
        } else {
          glue::glue("Flujo hacia la {categoria_lab}")
        }

        tabla <- armo_tabla_sankey(
            preparo_base(df_p, periodo_base = input$comp_periodo_base),
            categoria = input$comp_category) |>
          dplyr::mutate(dplyr::across(c(from, to), sankey_label_legible))

        highcharter::hchart(tabla, "sankey", name = sentido_label) |>
          hc_subtitle(text = glue::glue("Panel {anio} - trimestre {trim} y {trim_post}")) |>
          hc_plotOptions(sankey = list(
            nodes = sankey_nodes_orden(c("Ocupados", "Desocupados",
                                         "Inactivos", "Trab. familiares"))
          )) |>
          hc_add_theme(hc_theme_estacion_r)
      }

      ### Sub-tab "Tasas": serie temporal de Persistencia/Salida/Entrada
      ### (issue #22). Reusa el helper arma_line_chart_areaspline.
      output$tasas_chart <- renderHighchart({
        shiny::validate(shiny::need(
          nrow(df_tasas_cond_act) > 0,
          "Histórico de tasas todavía no fue computado. Correr ETL/08-build_tasas_historico.R."
        ))
        shiny::validate(shiny::need(
          length(input$tasas_tipo) > 0,
          "Seleccioná al menos un tipo de tasa."
        ))

        df_data <- df_tasas_cond_act |>
          filter(categoria == input$tasas_category) |>
          filter(input$tasas_duo == "todos" |
                   stringr::str_ends(as.character(periodo), input$tasas_duo)) |>
          arrange(periodo) |>
          tidyr::pivot_longer(c(persistencia, salida, entrada),
                              names_to = "to", values_to = "weight") |>
          mutate(to = recode(to,
                             persistencia = "Persistencia",
                             salida = "Salida",
                             entrada = "Entrada"),
                 id = paste0(categoria, "_", to)) |>
          filter(to %in% input$tasas_tipo) |>
          mutate(isExtremo = (weight == max(weight, na.rm = TRUE)) |
                              (weight == min(weight, na.rm = TRUE)),
                 .by = to)

        arma_line_chart_areaspline(
          df_data = df_data,
          levels_periodo = levels(df_tasas_cond_act$periodo),
          mostrar_pandemia = input$tasas_duo == "todos",
          tick_interval = if (input$tasas_duo == "todos") 4 else 1,
          excluir_intervencion = isTRUE(input$excluir_int_tasas),
          caption_text = paste0(
            "Tasas de movilidad por panel para los ",
            switch(input$tasas_category,
                   Ocupado = "Ocupados",
                   Desocupado = "Desocupados",
                   Inactivo = "Inactivos"),
            ". Elaboración propia en base a EPH-INDEC."
          )
        )
      })

      ### Alertas de período de intervención INDEC (Foto + Comparar).
      output$alert_int_foto <- renderUI({
        alerta_intervencion_indec(input$anio_ant)
      })
      output$alert_int_comparar <- renderUI({
        alerta_intervencion_indec(c(input$comp_anio_a, input$comp_anio_b))
      })

      ### Aviso de modo Interanual no soportado en Película/Tasas (#44).
      output$aviso_anual_pelicula <- renderUI({
        alerta_modo_anual_no_soportado(tipo_duo())
      })
      output$aviso_anual_tasas <- renderUI({
        alerta_modo_anual_no_soportado(tipo_duo())
      })

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
        ### Issue #44: durante el toggle intertrim/anual, el panel puede
        ### estar vacío unos ms hasta que los selectores se actualicen.
        ### req() pausa el render sin tirar error.
        req(nrow(df_eph_panel()) > 0)

        tabla_sankey <- armo_tabla_sankey(
            table = preparo_base(
              df = df_eph_panel(),
              periodo_base = input$periodo_base),
            categoria = input$category) |>
          dplyr::mutate(dplyr::across(c(from, to), sankey_label_legible))
        req(nrow(tabla_sankey) > 0)

        highcharter::hchart(
          object = tabla_sankey,
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
          hc_plotOptions(sankey = list(
            nodes = sankey_nodes_orden(c("Ocupados", "Desocupados",
                                         "Inactivos", "Trab. familiares"))
          )) |>
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
          excluir_intervencion = isTRUE(input$excluir_int_pelicula),
          caption_text = "Elaboración propia en base a la EPH-INDEC. Arrastrá horizontalmente para hacer zoom · Click en una serie para mostrarla u ocultarla."
        )
      })

    })
  })
}
