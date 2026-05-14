### Módulo Shiny genérico para los análisis de panel de la EPH (issue #12).
###
### Reemplaza a los 3 módulos específicos (mod_analisis_cond_act,
### mod_analisis_cat_ocup, mod_analisis_formalidad) por uno solo
### config-driven. Ver R/configs_analisis.R para los configs disponibles.
###
### Estructura común que cubre el módulo:
###   - Tab Foto       : Sankey + matriz de transición + 4 value boxes (1 pob + 3 tasas)
###   - Tab Película   : line chart areaspline histórico con filtros NLQ
###   - Tab Tasas      : line chart areaspline de tasas (Persistencia/Salida/Entrada)
###   - Tab Comparar   : 2 Sankeys lado a lado (funcional u opcional placeholder)
###
### Opcional según config:
###   - Toggle "Definición de informalidad" (clásica/ampliada) en formalidad.


# UI del módulo --------------------------------------------------------------

mod_analisis_ui <- function(id, config) {
  ns <- NS(id)

  ### --- Filtros NLQ del Sankey ("Foto") ---
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
                  choices = config$choices_categoria_foto),
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

  ### --- Filtros NLQ de la serie histórica ("Película") ---
  filtros_pelicula <- filter_query(
    prefix_text = "",
    filter_preposition(
      "Mostrar el flujo desde",
      selectInput(inputId = ns("desde"),
                  label = "Desde",
                  choices = config$choices_pelicula_desde,
                  selected = config$default_pelicula_desde),
      ""
    ),
    filter_preposition(
      "hacia",
      selectInput(inputId = ns("hacia"),
                  label = "Hacia",
                  choices = config$choices_pelicula_hacia,
                  selected = config$default_pelicula_hacia,
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

  ### --- Filtros NLQ de la sub-tab Tasas ---
  ### Si el config pide selector de tipo de tasa (cond_act), incluimos el
  ### multiselect Persistencia/Salida/Entrada. En cat_ocup/formalidad se
  ### muestran siempre las 3.
  filtros_tasas <- if (isTRUE(config$incluir_selector_tipo_tasa)) {
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
                    choices = config$choices_tasas_categoria,
                    selected = config$default_tasas_categoria),
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
    )
  } else {
    filter_query(
      prefix_text = "",
      filter_preposition(
        "Mostrar la evolución de las tasas para los",
        selectInput(inputId = ns("tasas_category"),
                    label = "Categoría",
                    choices = config$choices_tasas_categoria,
                    selected = config$default_tasas_categoria),
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
    )
  }

  ### --- Tab "Comparar": funcional o placeholder según config ---
  tab_comparar <- if (isTRUE(config$incluir_comparar_funcional)) {
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
                      choices = config$choices_categoria_foto),
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
  } else {
    bslib::nav_panel(
      title = "Comparar",
      icon = icon("layer-group"),
      card(
        class = "text-center",
        br(), br(),
        h2("Próximamente", class = "hero-title"),
        p("La comparación entre dos años para el mismo dúo trimestral va a estar disponible para este análisis en una próxima iteración."),
        p(em("Por ahora podés usarla en Condición de actividad.")),
        br(), br()
      )
    )
  }

  ### --- Toggle "Definición de informalidad" (solo formalidad) ---
  toggle_definicion <- if (isTRUE(config$incluir_toggle_definicion)) {
    card(
      class = "definicion-card",
      div(
        class = "filter-query nlq-styling definicion-toggle",
        tags$span(class = "preposition-affix",
                  tags$strong("Definición de informalidad:")),
        selectInput(inputId = ns("definicion"),
                    label = NULL,
                    choices = c("clásica (asalariados · 2003+)" = "clasica",
                                "ampliada (todos los ocupados · 2023+)" = "ampliada"),
                    selected = "clasica",
                    width = "auto"),
        bslib::tooltip(
          bsicons::bs_icon("info-circle",
                           style = "margin-left: 6px; color: #405BFF; cursor: help;"),
          tags$div(
            tags$strong("Clásica:"),
            " informal si NO le hacen descuento jubilatorio. Solo asalariados. Disponible 2003-actual.",
            tags$br(), tags$br(),
            tags$strong("Ampliada (OIT 2023):"),
            " incluye cuenta propia (formal si paga monotributo o aportes). Disponible desde 2023-T4."
          ),
          placement = "right"
        )
      )
    )
  } else {
    NULL
  }

  ### --- UI completa: Foto + Película + Tasas + Comparar ---
  contenido_tabs <- bslib::navset_card_underline(
    bslib::nav_panel(
      title = "Foto",
      icon = icon("camera-retro"),
      fluidRow(filtros_foto),
      uiOutput(ns("alert_int_foto")),

      ### Cuatro tarjetas destacadas: población base + 3 tasas (issues
      ### #16 + #21 + #34). Población define el "100%" sobre el cual se
      ### calculan las tasas; va primera. Persistencia es el dato principal
      ### de movilidad y va con `theme = "primary"` (azul Estación R).
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
          showcase = bs_icon(config$showcase_pob_icon),
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
      ### Proporción 5/7 para que la matriz NxN no haga scroll horizontal.
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
              strong("Desde:"), "primera categoría",
              br(),
              strong("Hacia:"), "segunda categoría",
              br(),
              "Y el panel en el eje x es", strong("2023_t1-t2"),
              ", la interpretación sería:",
              br(), br(),
              em("Entre la población de la primera categoría en el trimestre 1 del año 2023, el X% pasó a la segunda categoría para el trimestre 2 del mismo año"))
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
      filtros_tasas,
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
    tab_comparar
  )

  ### Si hay toggle de definición, lo prependeamos arriba de las tabs.
  if (!is.null(toggle_definicion)) {
    tagList(toggle_definicion, contenido_tabs)
  } else {
    contenido_tabs
  }
}


# Server del módulo ----------------------------------------------------------

mod_analisis_server <- function(id, config,
                                tipo_duo = shiny::reactive("trimestral")) {
  moduleServer(id, function(input, output, session) {

    ### Definición efectiva (solo formalidad la usa). Si el módulo no incluye
    ### toggle, devuelve NULL y los config_fns se evalúan en su rama default.
    definicion <- reactive({
      if (isTRUE(config$incluir_toggle_definicion)) input$definicion else NULL
    })

    ### Variable de panel efectiva (resuelta dinámicamente para formalidad).
    var_panel_actual <- reactive({
      if (isTRUE(config$incluir_toggle_definicion) &&
          !is.null(config$.resolver_var_panel)) {
        config$.resolver_var_panel(definicion())
      } else {
        config$var_panel
      }
    })

    ### Periodos / años válidos según el modo activo (issue #44).
    periodos_actuales <- reactive({
      if (tipo_duo() == "anual") periodos_disponibles_anual
      else periodos_disponibles
    })
    anios_actuales <- reactive({
      if (tipo_duo() == "anual") anios_disponibles_anual
      else anios_disponibles
    })

    ### Datasets históricos según modo + definición (issue #46).
    df_pelicula_actual <- reactive({
      config$pelicula_df_fn(tipo_duo(), definicion())
    })
    df_tasas_actual <- reactive({
      config$tasas_df_fn(tipo_duo(), definicion())
    })

    ### Alerta del período de intervención INDEC (Foto).
    output$alert_int_foto <- renderUI({
      alerta_intervencion_indec(input$anio_ant)
    })

    ### --- Observers de actualización dinámica de selectInputs ---

    ### Choices del selector tasas_duo y duo según modo.
    observeEvent(tipo_duo(), {
      choices_nuevos <- if (tipo_duo() == "anual") {
        c("Todos los trimestres" = "todos",
          "T1" = "t1", "T2" = "t2", "T3" = "t3", "T4" = "t4")
      } else {
        c("Todos los trimestres" = "todos",
          "1-2" = "t1-t2", "2-3" = "t2-t3", "3-4" = "t3-t4", "4-1" = "t4-t1")
      }
      updateSelectInput(session, "tasas_duo",
                        choices = choices_nuevos, selected = "todos")
      updateSelectInput(session, "duo",
                        choices = choices_nuevos, selected = "todos")
    })

    ### Cuando cambia el modo, actualizar selector de año.
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

    ### Recalcula los duos válidos cuando cambia año o modo.
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
      updateSelectInput(session, "trimestre_ant",
                        choices = duos, selected = seleccion_nueva)
    })

    ### --- Observe principal: outputs de la tab Foto + helpers reactivos ---
    observe({

      anio_ant <- as.numeric(input$anio_ant)
      anio_post <- ifelse(as.numeric(input$trimestre_ant) %in% c(1:3),
                          as.numeric(input$anio_ant),
                          as.numeric(input$anio_ant) + 1)
      trim_ant <- as.numeric(input$trimestre_ant)
      trim_post <- ifelse(as.numeric(input$trimestre_ant) %in% c(1:3),
                          as.numeric(input$trimestre_ant) + 1, 1)

      sentido <- input$periodo_base
      def <- definicion()
      vp <- var_panel_actual()

      ### Etiqueta del value box "Población" (texto + número formateado).
      output$pob <- renderText({
        config$pob_label_fn(input, definicion = def)
      })
      output$pob_n <- renderText({
        config$pob_n_fn(input,
                        anio_ant = anio_ant, trim_ant = trim_ant,
                        anio_post = anio_post, trim_post = trim_post,
                        tipo_duo = tipo_duo(),
                        var_panel = vp, definicion = def)
      })
      output$periodo <- renderText({
        paste("Año ", anio_ant, ", trimestre ", trim_ant)
      })

      ### Panel base reusado por Sankey + matriz + tarjetas de tasas.
      df_eph_panel <- reactive({
        ### Si el config no especifica vars_panel_eph, usar el default de
        ### armo_base_panel (cond_act es el único caso así).
        if (is.null(config$vars_panel_eph)) {
          armo_base_panel(anio_0 = anio_ant, trimestre_0 = trim_ant,
                          anio_1 = anio_post, trimestre_1 = trim_post,
                          window = tipo_duo())
        } else {
          armo_base_panel(anio_0 = anio_ant, trimestre_0 = trim_ant,
                          anio_1 = anio_post, trimestre_1 = trim_post,
                          variables = config$vars_panel_eph,
                          window = tipo_duo())
        }
      })

      ### Tarjetas con tasas destacadas (issue #16 · opción B).
      ### Si el config trae validate_pre_render_fn (formalidad ampliada),
      ### devolvemos NA cuando no hay datos para no romper renders.
      tasas <- reactive({
        if (!is.null(config$validate_pre_render_fn)) {
          msg <- config$validate_pre_render_fn(input, df_eph_panel(), def)
          if (!is.null(msg)) {
            return(list(persistencia = NA, salida = NA, entrada = NA))
          }
        }
        arma_tasas_destacadas(
          df_panel = df_eph_panel(),
          var = vp,
          etiquetas = config$etiquetas_codigo,
          categoria = input$category
        )
      })

      ### Delta vs mismo dúo trimestral del año anterior (issue #21).
      tasas_anio_ant <- reactive({
        anio_prev <- anio_ant - 1
        if (anio_prev < min(anios_disponibles)) return(NULL)
        anio_post_prev <- anio_post - 1
        existe <- paste(anio_prev, trim_ant) %in%
                    paste(periodos_disponibles$ANO4, periodos_disponibles$TRIMESTRE) &&
                  paste(anio_post_prev, trim_post) %in%
                    paste(periodos_disponibles$ANO4, periodos_disponibles$TRIMESTRE)
        if (!existe) return(NULL)
        df_prev <- if (is.null(config$vars_panel_eph)) {
          armo_base_panel(anio_0 = anio_prev, trimestre_0 = trim_ant,
                          anio_1 = anio_post_prev, trimestre_1 = trim_post,
                          window = tipo_duo())
        } else {
          armo_base_panel(anio_0 = anio_prev, trimestre_0 = trim_ant,
                          anio_1 = anio_post_prev, trimestre_1 = trim_post,
                          variables = config$vars_panel_eph,
                          window = tipo_duo())
        }
        if (!is.null(config$validate_pre_render_fn)) {
          msg <- config$validate_pre_render_fn(input, df_prev, def)
          if (!is.null(msg)) return(NULL)
        }
        arma_tasas_destacadas(
          df_panel = df_prev, var = vp,
          etiquetas = config$etiquetas_codigo,
          categoria = input$category
        )
      })

      delta_label <- reactive({
        anio_prev <- anio_ant - 1
        glue::glue("vs {anio_prev} T{trim_ant}-T{trim_post}")
      })

      output$tasa_persistencia <- renderText({
        v <- tasas()$persistencia
        if (is.na(v)) "—" else paste0(v, "%")
      })
      output$tasa_salida <- renderText({
        v <- tasas()$salida
        if (is.na(v)) "—" else paste0(v, "%")
      })
      output$tasa_entrada <- renderText({
        v <- tasas()$entrada
        if (is.na(v)) "—" else paste0(v, "%")
      })

      output$delta_persistencia <- renderText({
        ant <- tasas_anio_ant()
        if (is.null(ant) || is.na(tasas()$persistencia)) return("sin comparación previa")
        paste(formato_delta(tasas()$persistencia - ant$persistencia), delta_label())
      })
      output$delta_salida <- renderText({
        ant <- tasas_anio_ant()
        if (is.null(ant) || is.na(tasas()$salida)) return("sin comparación previa")
        paste(formato_delta(tasas()$salida - ant$salida), delta_label())
      })
      output$delta_entrada <- renderText({
        ant <- tasas_anio_ant()
        if (is.null(ant) || is.na(tasas()$entrada)) return("sin comparación previa")
        paste(formato_delta(tasas()$entrada - ant$entrada), delta_label())
      })

      ### Matriz de transición (issue #16 · opción A).
      output$matriz_transicion <- gt::render_gt({
        if (!is.null(config$validate_pre_render_fn)) {
          msg <- config$validate_pre_render_fn(input, df_eph_panel(), def)
          shiny::validate(shiny::need(is.null(msg), msg))
        }
        matriz <- arma_matriz_transicion(
          df_panel = df_eph_panel(),
          var = vp,
          etiquetas = config$etiquetas_codigo
        )
        arma_matriz_transicion_gt(matriz, titulo = NULL)
      })

      ### Sankey principal (Foto).
      output$sankey <- renderHighchart({
        ### Issue #44: req() pausa el render durante transiciones del
        ### toggle intertrim/anual cuando el panel queda vacío unos ms.
        req(nrow(df_eph_panel()) > 0)

        if (!is.null(config$validate_pre_render_fn)) {
          msg <- config$validate_pre_render_fn(input, df_eph_panel(), def)
          shiny::validate(shiny::need(is.null(msg), msg))
        }

        tabla_sankey <- armo_tabla_sankey(
            table = preparo_base(
              df = df_eph_panel(),
              periodo_base = input$periodo_base,
              var = vp,
              etiquetas = config$etiquetas_codigo),
            categoria = input$category) |>
          dplyr::mutate(dplyr::across(c(from, to), sankey_label_legible))
        req(nrow(tabla_sankey) > 0)

        ### Caption del Sankey (con extra de definición si aplica).
        caption_text <- "Fuente: Elaboración propia en base a la EPH-INDEC"
        if (!is.null(config$caption_sankey_extra_fn)) {
          caption_text <- paste(caption_text,
                                config$caption_sankey_extra_fn(input, def))
        }

        highcharter::hchart(
          object = tabla_sankey,
          "sankey",
          name = config$sentido_label_fn(input, sentido_t = sentido,
                                          definicion = def)
        ) |>
          hc_title(text = config$titulo_sankey) |>
          hc_subtitle(text = glue(
            "Panel {ifelse(trim_ant %in% 1:3,
              paste0(anio_ant, ' - ', 'trimestre ', trim_ant, ' y ', trim_post),
              paste0(anio_ant, ' - ', 'trimestre ', trim_ant, ' y ', anio_ant + 1, ' trimestre ', trim_post))}")) |>
          hc_caption(text = caption_text) |>
          hc_plotOptions(sankey = list(
            nodes = sankey_nodes_orden(config$sankey_nodes_labels)
          )) |>
          hc_add_theme(hc_theme_estacion_r)
      })

      ### Sub-tab "Tasas": serie temporal de Persistencia/Salida/Entrada (issue #22).
      output$tasas_chart <- renderHighchart({
        df_tasas <- df_tasas_actual()
        shiny::validate(shiny::need(
          nrow(df_tasas) > 0,
          "Histórico de tasas todavía no fue computado para este modo. Correr ETL/08-build_tasas_historico.R o ETL/11-build_historicos_anuales.R."
        ))
        ### En cond_act: validar que haya al menos un tipo de tasa elegida.
        if (isTRUE(config$incluir_selector_tipo_tasa)) {
          shiny::validate(shiny::need(
            length(input$tasas_tipo) > 0,
            "Seleccioná al menos un tipo de tasa."
          ))
        }

        df_data <- df_tasas |>
          dplyr::filter(categoria == input$tasas_category) |>
          dplyr::filter(input$tasas_duo == "todos" |
                          stringr::str_ends(as.character(periodo), input$tasas_duo)) |>
          dplyr::arrange(periodo) |>
          tidyr::pivot_longer(c(persistencia, salida, entrada),
                              names_to = "to", values_to = "weight") |>
          dplyr::mutate(to = dplyr::recode(to,
                                            persistencia = "Persistencia",
                                            salida = "Salida",
                                            entrada = "Entrada"),
                         id = paste0(categoria, "_", to))

        ### Filtrar por tipo de tasa si el config lo expone.
        if (isTRUE(config$incluir_selector_tipo_tasa)) {
          df_data <- df_data |> dplyr::filter(to %in% input$tasas_tipo)
        }

        df_data <- df_data |>
          dplyr::mutate(isExtremo = (weight == max(weight, na.rm = TRUE)) |
                                     (weight == min(weight, na.rm = TRUE)),
                         .by = to)

        arma_line_chart_areaspline(
          df_data = df_data,
          levels_periodo = levels(df_tasas$periodo),
          mostrar_pandemia = config$mostrar_pandemia_fn(input, "tasas", def),
          tick_interval = if (input$tasas_duo == "todos") 4 else 1,
          excluir_intervencion = isTRUE(input$excluir_int_tasas),
          caption_text = config$tasas_caption_fn(input, definicion = def)
        )
      })

      ### Sub-tab "Película": serie histórica del Sankey por categoría destino.
      output$line <- renderHighchart({
        df_pelicula <- df_pelicula_actual()
        shiny::validate(shiny::need(
          nrow(df_pelicula) > 0,
          "Histórico de Película todavía no fue computado para este modo. Correr ETL/11-build_historicos_anuales.R o (formalidad ampliada) ETL/07-build_panel_formalidad_ampliada.R."
        ))

        df_data <- df_pelicula |>
          dplyr::filter(from == input$desde, to %in% input$hacia) |>
          dplyr::filter(input$duo == "todos" |
                          stringr::str_ends(as.character(periodo), input$duo)) |>
          dplyr::arrange(periodo) |>
          dplyr::mutate(
            to = config$pelicula_serie_label_fn(from, to),
            id = stringr::str_replace_all(id, "tant", "t0"),
            id = stringr::str_replace_all(id, "tpost", "t2")
          ) |>
          dplyr::mutate(isExtremo = (weight == max(weight, na.rm = TRUE)) |
                                     (weight == min(weight, na.rm = TRUE)),
                         .by = to)

        arma_line_chart_areaspline(
          df_data = df_data,
          levels_periodo = levels(df_pelicula$periodo),
          mostrar_pandemia = config$mostrar_pandemia_fn(input, "pelicula", def),
          tick_interval = if (input$duo == "todos") 4 else 1,
          excluir_intervencion = isTRUE(input$excluir_int_pelicula),
          caption_text = "Elaboración propia en base a la EPH-INDEC. Arrastrá horizontalmente para hacer zoom · Click en una serie para mostrarla u ocultarla."
        )
      })

    })  ### fin observe principal

    ### --- Tab "Comparar" (solo si config lo activa funcional) ---
    if (isTRUE(config$incluir_comparar_funcional)) {
      output$alert_int_comparar <- renderUI({
        alerta_intervencion_indec(c(input$comp_anio_a, input$comp_anio_b))
      })

      output$comp_header_a <- renderText({
        paste("Panel A · Año", input$comp_anio_a)
      })
      output$comp_header_b <- renderText({
        paste("Panel B · Año", input$comp_anio_b)
      })

      ### Función helper para armar uno de los Sankeys del Comparar.
      ### Reusa la lógica del Sankey de Foto pero con inputs prefijados con
      ### `comp_` y un panel armado en el momento.
      arma_sankey_comparativo <- function(anio_panel) {
        anio <- as.numeric(anio_panel)
        trim <- as.numeric(input$comp_trimestre)
        anio_post <- if (trim %in% 1:3) anio else anio + 1
        trim_post <- if (trim %in% 1:3) trim + 1 else 1

        df_p <- if (is.null(config$vars_panel_eph)) {
          armo_base_panel(anio_0 = anio, trimestre_0 = trim,
                          anio_1 = anio_post, trimestre_1 = trim_post,
                          window = tipo_duo())
        } else {
          armo_base_panel(anio_0 = anio, trimestre_0 = trim,
                          anio_1 = anio_post, trimestre_1 = trim_post,
                          variables = config$vars_panel_eph,
                          window = tipo_duo())
        }

        ### Construir un input "sintético" para reusar sentido_label_fn con
        ### los selectores comp_*. La función espera input$category y el
        ### sentido_t como argumento separado.
        sintetico <- list(category = input$comp_category)
        nombre_serie <- config$sentido_label_fn(sintetico,
                                                 sentido_t = input$comp_periodo_base,
                                                 definicion = definicion())

        tabla <- armo_tabla_sankey(
            preparo_base(df_p, periodo_base = input$comp_periodo_base,
                         var = var_panel_actual(),
                         etiquetas = config$etiquetas_codigo),
            categoria = input$comp_category) |>
          dplyr::mutate(dplyr::across(c(from, to), sankey_label_legible))

        highcharter::hchart(tabla, "sankey", name = nombre_serie) |>
          hc_subtitle(text = glue::glue("Panel {anio} - trimestre {trim} y {trim_post}")) |>
          hc_plotOptions(sankey = list(
            nodes = sankey_nodes_orden(config$sankey_nodes_labels)
          )) |>
          hc_add_theme(hc_theme_estacion_r)
      }

      output$sankey_a <- renderHighchart({
        arma_sankey_comparativo(input$comp_anio_a)
      })
      output$sankey_b <- renderHighchart({
        arma_sankey_comparativo(input$comp_anio_b)
      })
    }

    ### Issue #74 (hub-and-spoke): cuando el módulo vive dentro de un
    ### conditionalPanel (vista no activa), Shiny por default suspende sus
    ### outputs. Eso rompe el reflow de Highcharts al volver a la vista.
    ### suspendWhenHidden = FALSE mantiene los outputs vivos y un JS handler
    ### (www/reflow_charts.js) llama a chart.reflow() cuando cambia la vista.
    ###
    ### Los outputs se registran dentro de observe(), así que aplicamos
    ### outputOptions desde session$onFlushed (que corre después del primer
    ### flush, cuando ya existen).
    session$onFlushed(function() {
      nombres <- c("sankey", "line", "tasas_chart")
      if (isTRUE(config$incluir_comparar_funcional)) {
        nombres <- c(nombres, "sankey_a", "sankey_b")
      }
      for (n in nombres) {
        tryCatch(
          outputOptions(output, n, suspendWhenHidden = FALSE),
          error = function(e) NULL
        )
      }
    }, once = TRUE)
  })
}
