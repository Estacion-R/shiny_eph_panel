### Módulo Shiny para el análisis "Categoría ocupacional" de la EPH.
###
### Encapsula Foto (Sankey de flujo entre Patrón / Cuenta propia /
### Asalariado / TFSR dentro de la población Ocupada en un panel
### trimestral) + Película (línea histórica del flujo).
###
### Construido en Fase 3 del epic #6, copy-paste del módulo de Condición
### de actividad con los ajustes específicos. Si en Fase 4 ambos crecen
### a 3 análisis, conviene refactorizar a un módulo genérico parametrizable.


# UI del módulo --------------------------------------------------------------

mod_cat_ocup_ui <- function(id) {
  ns <- NS(id)

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
                  choices = c("Patrones" = "Patron",
                              "Cuenta propia" = "Cuenta_propia",
                              "Asalariados" = "Asalariado",
                              "Trab familiares" = "TFSR")),
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

  filtros_pelicula <- filter_query(
    prefix_text = "",
    filter_preposition(
      "Mostrar el flujo desde",
      selectInput(inputId = ns("desde"),
                  label = "Desde",
                  choices = c("Patrones" = "Patron_t0",
                              "Cuenta propia" = "Cuenta_propia_t0",
                              "Asalariados" = "Asalariado_t0",
                              "Trab familiares" = "TFSR_t0"),
                  selected = "Asalariado_t0"),
      ""
    ),
    filter_preposition(
      "hacia",
      selectInput(inputId = ns("hacia"),
                  label = "Hacia",
                  choices = c("Patrones" = "Patron_t1",
                              "Cuenta propia" = "Cuenta_propia_t1",
                              "Asalariados" = "Asalariado_t1",
                              "Trab familiares" = "TFSR_t1"),
                  selected = c("Cuenta_propia_t1", "Patron_t1"),
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

  bslib::navset_card_underline(
    bslib::nav_panel(
      title = "Foto",
      icon = icon("camera-retro"),
      fluidRow(filtros_foto),
      uiOutput(ns("alert_int_foto")),

      ### Cuatro tarjetas destacadas: población base (1ra, define el 100%)
      ### + 3 tasas. Jerarquía: Persistencia primary (azul), las otras 3
      ### con borde neutro (issues #16 + #21 + #34).
      layout_columns(
        col_widths = c(3, 3, 3, 3),
        value_box(
          title = tagList(
            textOutput(ns("pob"), inline = TRUE),
            bslib::popover(
              bsicons::bs_icon("info-circle",
                               style = "color: #405BFF; cursor: help; margin-left: 8px; font-size: 0.85em;"),
              "Las tarjetas de la derecha se calculan respecto a esta población. La matriz muestra todas las transiciones del panel.",
              placement = "right"
            )
          ),
          value = textOutput(ns("pob_n")),
          showcase = bs_icon("person-badge"),
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
      filtros_pelicula,
      div(
        style = "text-align: center; margin: 4px 0 12px 0;",
        checkboxInput(ns("excluir_int_pelicula"),
                      label = "Excluir período de intervención INDEC (2007-2015)",
                      value = FALSE)
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
      filter_query(
        prefix_text = "",
        filter_preposition(
          "Mostrar la evolución de las tasas para los",
          selectInput(inputId = ns("tasas_category"),
                      label = "Categoría",
                      choices = c("Patrones" = "Patron",
                                  "Cuenta propia" = "Cuenta_propia",
                                  "Asalariados" = "Asalariado",
                                  "Trab familiares" = "TFSR"),
                      selected = "Asalariado"),
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
      card(
        class = "text-center",
        br(), br(),
        h2("Próximamente", class = "hero-title"),
        p("La comparación entre dos años para el mismo dúo trimestral va a estar disponible para Categoría ocupacional en la próxima iteración."),
        p(em("Por ahora podés usarla en Condición de actividad.")),
        br(), br()
      )
    )
  )
}


# Server del módulo ----------------------------------------------------------

mod_cat_ocup_server <- function(id, tipo_duo = shiny::reactive("trimestral")) {
  moduleServer(id, function(input, output, session) {

    ### Alerta del período de intervención INDEC (Foto).
    output$alert_int_foto <- renderUI({
      alerta_intervencion_indec(input$anio_ant)
    })


    ### Etiquetas humanas para textos del UI (singular / plural / variable).
    etiqueta_singular <- function(cat) {
      switch(cat,
             Patron = "Patrón",
             Cuenta_propia = "Cuenta propia",
             Asalariado = "Asalariado",
             TFSR = "Trabajador familiar")
    }
    etiqueta_plural <- function(cat) {
      switch(cat,
             Patron = "Patrones",
             Cuenta_propia = "Cuenta propia",
             Asalariado = "Asalariados",
             TFSR = "Trab familiares")
    }

    ### Periodos / años válidos según el modo activo (issue #44).
    periodos_actuales <- reactive({
      if (tipo_duo() == "anual") periodos_disponibles_anual
      else periodos_disponibles
    })
    anios_actuales <- reactive({
      if (tipo_duo() == "anual") anios_disponibles_anual
      else anios_disponibles
    })

    ### Datasets históricos según modo (issue #46).
    df_cat_ocup_actual <- reactive({
      if (tipo_duo() == "anual") df_cat_ocup_anual else df_cat_ocup
    })
    df_tasas_cat_ocup_actual <- reactive({
      if (tipo_duo() == "anual") df_tasas_cat_ocup_anual else df_tasas_cat_ocup
    })

    ### Choices del selector tasas_duo según modo.
    observeEvent(tipo_duo(), {
      choices_nuevos <- if (tipo_duo() == "anual") {
        c("Todos los trimestres" = "todos",
          "T1" = "t1", "T2" = "t2", "T3" = "t3", "T4" = "t4")
      } else {
        c("Todos los trimestres" = "todos",
          "1-2" = "t1-t2", "2-3" = "t2-t3", "3-4" = "t3-t4", "4-1" = "t4-t1")
      }
      updateSelectInput(session, "tasas_duo",
                        choices = choices_nuevos,
                        selected = "todos")
      ### Mismo selector "Trimestres" en sub-tab Película (input `duo`).
      updateSelectInput(session, "duo",
                        choices = choices_nuevos,
                        selected = "todos")
    })

    ### Cuando cambia el modo, actualizar el selector de año.
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
      tipo_duo()
      req(anio)

      duos <- duos_disponibles_por_anio(anio, periodos_actuales(),
                                        window = tipo_duo())
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
      cat_singular <- etiqueta_singular(input$category)
      cat_plural   <- etiqueta_plural(input$category)

      output$pob <- renderText({
        paste0("Población: ", cat_plural)
      })

      output$pob_n <- renderText({
        ### Cantidad ponderada de personas en la categoría seleccionada en t0.
        df_panel <- armo_base_panel(
          anio_0 = anio_ant, trimestre_0 = trim_ant,
          anio_1 = anio_post, trimestre_1 = trim_post,
          variables = c("ESTADO", "CAT_OCUP", "PONDERA"),
          window = tipo_duo()
        )

        codigo_cat <- match(input$category,
                            c("Patron", "Cuenta_propia", "Asalariado", "TFSR"))

        n_pob <- df_panel |>
          filter(CAT_OCUP == codigo_cat) |>
          summarise(n = sum(PONDERA, na.rm = TRUE)) |>
          pull(n)

        format(n_pob, big.mark = ".", decimal.mark = ",")
      })

      output$periodo <- renderText({
        paste("Año ", anio_ant, ", trimestre ", trim_ant)
      })

      df_eph_panel <- reactive({
        armo_base_panel(
          anio_0 = anio_ant, trimestre_0 = trim_ant,
          anio_1 = anio_post, trimestre_1 = trim_post,
          variables = c("ESTADO", "CAT_OCUP", "PONDERA"),
          window = tipo_duo()
        )
      })

      ### Tarjetas con tasas destacadas (issue #16 · opción B).
      tasas <- reactive({
        arma_tasas_destacadas(
          df_panel = df_eph_panel(),
          var = "CAT_OCUP",
          etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),
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
        df_prev <- armo_base_panel(
          anio_0 = anio_prev, trimestre_0 = trim_ant,
          anio_1 = anio_post_prev, trimestre_1 = trim_post,
          variables = c("ESTADO", "CAT_OCUP", "PONDERA"),
          window = tipo_duo()
        )
        arma_tasas_destacadas(
          df_panel = df_prev, var = "CAT_OCUP",
          etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),
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
          var = "CAT_OCUP",
          etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR")
        )
        arma_matriz_transicion_gt(matriz, titulo = NULL)
      })

      ### Sub-tab "Tasas" (issue #22).
      output$tasas_chart <- renderHighchart({
        df_tasas <- df_tasas_cat_ocup_actual()
        shiny::validate(shiny::need(
          nrow(df_tasas) > 0,
          "Histórico de tasas todavía no fue computado para este modo. Correr ETL/08-build_tasas_historico.R o ETL/11-build_historicos_anuales.R."
        ))

        df_data <- df_tasas |>
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
          mutate(isExtremo = (weight == max(weight, na.rm = TRUE)) |
                              (weight == min(weight, na.rm = TRUE)),
                 .by = to)

        arma_line_chart_areaspline(
          df_data = df_data,
          levels_periodo = levels(df_tasas$periodo),
          mostrar_pandemia = input$tasas_duo == "todos",
          tick_interval = if (input$tasas_duo == "todos") 4 else 1,
          excluir_intervencion = isTRUE(input$excluir_int_tasas),
          caption_text = paste0(
            "Tasas de movilidad por panel para los ",
            etiqueta_plural(input$tasas_category),
            ". Elaboración propia en base a EPH-INDEC."
          )
        )
      })

      output$sankey <- renderHighchart({
        ### Issue #44: req() pausa el render durante transiciones del
        ### toggle intertrim/anual cuando el panel queda vacío unos ms.
        req(nrow(df_eph_panel()) > 0)

        tabla_sankey <- armo_tabla_sankey(
            table = preparo_base(
              df = df_eph_panel(),
              periodo_base = input$periodo_base,
              var = "CAT_OCUP",
              etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR")),
            categoria = input$category) |>
          dplyr::mutate(dplyr::across(c(from, to), sankey_label_legible))
        req(nrow(tabla_sankey) > 0)

        highcharter::hchart(
          object = tabla_sankey,
          "sankey",
          name = ifelse(sentido == "t_anterior",
                        glue::glue("Flujo desde {cat_plural}"),
                        glue::glue("Flujo hacia {cat_plural}"))
        ) |>
          hc_title(text = "Movilidad entre categorías ocupacionales.") |>
          hc_subtitle(text = glue(
            "Panel {ifelse(trim_ant %in% 1:3, paste0(anio_ant, ' - ', 'trimestre ', trim_ant, ' y ', trim_post),
          paste0(anio_ant, ' - ', 'trimestre ', trim_ant, ' y ', anio_ant + 1, ' trimestre ', trim_post))}")) |>
          hc_caption(text = "Fuente: Elaboración propia en base a la EPH-INDEC") |>
          hc_plotOptions(sankey = list(
            nodes = sankey_nodes_orden(c("Patrones", "Cuenta propia",
                                         "Asalariados", "Trab. familiares"))
          )) |>
          hc_add_theme(hc_theme_estacion_r)
      })

      output$line <- renderHighchart({
        ### Genera la etiqueta humana de la serie a partir de from/to.
        etiqueta_serie <- function(from, to) {
          partir_de <- gsub("_t0$", "", from)
          ir_a      <- gsub("_t1$", "", to)
          partir_de_h <- etiqueta_plural(partir_de)
          ir_a_h      <- etiqueta_plural(ir_a)

          if (partir_de == ir_a) {
            glue::glue("% de {partir_de_h} que siguen como {ir_a_h}")
          } else {
            glue::glue("% de {partir_de_h} que pasan a {ir_a_h}")
          }
        }

        df_pelicula <- df_cat_ocup_actual()
        shiny::validate(shiny::need(
          nrow(df_pelicula) > 0,
          "Histórico de Película todavía no fue computado para este modo. Correr ETL/11-build_historicos_anuales.R."
        ))
        df_data <- df_pelicula |>
          filter(from == input$desde, to %in% input$hacia) |>
          filter(input$duo == "todos" |
                   stringr::str_ends(as.character(periodo), input$duo)) |>
          arrange(periodo) |>
          mutate(to = purrr::map2_chr(from, to, etiqueta_serie),
                 id = stringr::str_replace_all(id, "tant", "t0"),
                 id = stringr::str_replace_all(id, "tpost", "t2")) |>
          mutate(isExtremo = (weight == max(weight, na.rm = TRUE)) |
                              (weight == min(weight, na.rm = TRUE)),
                 .by = to)

        arma_line_chart_areaspline(
          df_data = df_data,
          levels_periodo = levels(df_pelicula$periodo),
          mostrar_pandemia = input$duo == "todos",
          tick_interval = if (input$duo == "todos") 4 else 1,
          excluir_intervencion = isTRUE(input$excluir_int_pelicula),
          caption_text = "Elaboración propia en base a la EPH-INDEC. Arrastrá horizontalmente para hacer zoom · Click en una serie para mostrarla u ocultarla."
        )
      })

    })
  })
}
