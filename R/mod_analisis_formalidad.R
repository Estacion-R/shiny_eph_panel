### Módulo Shiny para el análisis "Formal / Informal" de la EPH.
###
### Universo: asalariados (CAT_OCUP = 3). Definición clásica EPH para
### serie larga 2003+: formal si paga aportes (PP07H = 1), informal si
### no (PP07H = 2). La medición ampliada (cuenta propia con monotributo,
### sector institucional) requiere variables disponibles desde 4T 2023
### que quedan para una iteración futura.


# UI del módulo --------------------------------------------------------------

mod_formalidad_ui <- function(id) {
  ns <- NS(id)

  ### Toggle de definición compartido entre Foto y Película. Lo ponemos
  ### arriba de las dos sub-tabs para que el usuario lo elija una sola vez
  ### y aplique a ambos gráficos.
  toggle_definicion <- div(
    class = "filter-query nlq-styling",
    style = "margin-bottom: 8px;",
    tags$span(class = "preposition-affix",
              "Definición de informalidad:"),
    selectInput(inputId = ns("definicion"),
                label = NULL,
                choices = c("clásica (asalariados · 2003+)" = "clasica",
                            "ampliada (todos los ocupados · 2023+)" = "ampliada"),
                selected = "clasica",
                width = "auto")
  )

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
                  choices = c("Formales" = "Formal",
                              "Informales" = "Informal")),
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
                  choices = c("Formales" = "Formal_t0",
                              "Informales" = "Informal_t0"),
                  selected = "Informal_t0"),
      ""
    ),
    filter_preposition(
      "hacia",
      selectInput(inputId = ns("hacia"),
                  label = "Hacia",
                  choices = c("Formales" = "Formal_t1",
                              "Informales" = "Informal_t1"),
                  selected = "Formal_t1",
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

  tagList(
    toggle_definicion,
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
            showcase = bs_icon("person-vcard"),
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
        card(
          full_screen = TRUE,
          min_height = "520px",
          highchartOutput(ns("line"), height = "100%")
        )
      )
    )
  )
}


# Server del módulo ----------------------------------------------------------

mod_formalidad_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    etiqueta_plural <- function(cat) {
      switch(cat,
             Formal = "Formales",
             Informal = "Informales")
    }

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
      cat_plural <- etiqueta_plural(input$category)

      ### Selección dinámica entre definición clásica y ampliada (issue #15).
      ### `definicion` controla:
      ###   - var_panel: nombre de la variable derivada en df_eph_full.
      ###   - df_serie: dataframe histórico para el line chart.
      ###   - universo: "asalariados" o "ocupados", para textos del UI.
      ###   - caption_def: texto explicativo en el caption del sankey.
      var_panel <- if (input$definicion == "ampliada") "formalidad_ampliada" else "formalidad"
      df_serie  <- if (input$definicion == "ampliada") df_formalidad_ampliada else df_formalidad
      universo  <- if (input$definicion == "ampliada") "ocupados" else "asalariados"
      caption_def <- if (input$definicion == "ampliada") {
        "Definición ampliada (OIT 2023, EPH 2023+): asalariados con PP07H + cuenta propia/patrones con PP05I/PP05K."
      } else {
        "Definición clásica EPH: solo asalariados (CAT_OCUP=3) vía PP07H."
      }

      ### Vars que necesitamos del microdato para los dos modos (siempre las
      ### incluimos para no recomputar al cambiar el toggle).
      vars_panel_eph <- c("ESTADO", "CAT_OCUP", "PP07H", "PP05I", "PP05K",
                          "formalidad", "formalidad_ampliada", "PONDERA")

      output$pob <- renderText({
        paste0(stringr::str_to_sentence(universo), " ", cat_plural)
      })

      output$pob_n <- renderText({
        df_panel <- armo_base_panel(
          anio_0 = anio_ant, trimestre_0 = trim_ant,
          anio_1 = anio_post, trimestre_1 = trim_post,
          df = df_eph_full,
          variables = vars_panel_eph
        )

        codigo <- match(input$category, c("Formal", "Informal"))

        n_pob <- df_panel |>
          filter(.data[[var_panel]] == codigo) |>
          summarise(n = sum(PONDERA, na.rm = TRUE)) |>
          pull(n)

        if (length(n_pob) == 0 || is.na(n_pob)) {
          "—"
        } else {
          format(n_pob, big.mark = ".", decimal.mark = ",")
        }
      })

      output$periodo <- renderText({
        paste("Año ", anio_ant, ", trimestre ", trim_ant)
      })

      df_eph_panel <- reactive({
        armo_base_panel(
          anio_0 = anio_ant, trimestre_0 = trim_ant,
          anio_1 = anio_post, trimestre_1 = trim_post,
          df = df_eph_full,
          variables = vars_panel_eph
        )
      })

      output$sankey <- renderHighchart({
        ### Validar que la definición ampliada tenga datos en el panel
        ### seleccionado (solo aplica para 2023-T4+).
        if (input$definicion == "ampliada") {
          n_validos <- df_eph_panel() |>
            filter(!is.na(formalidad_ampliada)) |>
            nrow()
          shiny::validate(shiny::need(
            n_validos > 0,
            "La definición ampliada está disponible desde 2023-T4. Elegí un panel más reciente o cambiá a definición clásica."
          ))
        }

        highcharter::hchart(
          object = armo_tabla_sankey(
            table = preparo_base(
              df = df_eph_panel(),
              periodo_base = input$periodo_base,
              var = var_panel,
              etiquetas = c("Formal", "Informal")),
            categoria = input$category),
          "sankey",
          name = ifelse(sentido == "t_anterior",
                        glue::glue("Flujo desde {universo} {cat_plural}"),
                        glue::glue("Flujo hacia {universo} {cat_plural}"))
        ) |>
          hc_title(text = "Movilidad entre Formales e Informales.") |>
          hc_subtitle(text = glue(
            "Panel {ifelse(trim_ant %in% 1:3, paste0(anio_ant, ' - ', 'trimestre ', trim_ant, ' y ', trim_post),
          paste0(anio_ant, ' - ', 'trimestre ', trim_ant, ' y ', anio_ant + 1, ' trimestre ', trim_post))}")) |>
          hc_caption(text = paste("Fuente: Elaboración propia en base a la EPH-INDEC.", caption_def)) |>
          hc_add_theme(hc_theme_estacion_r)
      })

      output$line <- renderHighchart({
        ### Validar que el dataframe histórico de la definición elegida
        ### tenga datos. Si la ampliada está vacía (rebuild aún no corrido),
        ### mostrar mensaje informativo.
        shiny::validate(shiny::need(
          nrow(df_serie) > 0,
          "Histórico de la definición ampliada todavía no fue computado. Correr ETL/07-build_panel_formalidad_ampliada.R o elegir definición clásica."
        ))

        etiqueta_serie <- function(from, to) {
          partir_de <- gsub("_t0$", "", from)
          ir_a      <- gsub("_t1$", "", to)
          partir_de_h <- etiqueta_plural(partir_de)
          ir_a_h      <- etiqueta_plural(ir_a)

          if (partir_de == ir_a) {
            glue::glue("% de {partir_de_h} que siguen {ir_a_h}")
          } else {
            glue::glue("% de {partir_de_h} que pasan a {ir_a_h}")
          }
        }

        df_data <- df_serie |>
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
          levels_periodo = levels(df_serie$periodo),
          mostrar_pandemia = input$duo == "todos" && input$definicion == "clasica",
          tick_interval = if (input$duo == "todos") 4 else 1,
          caption_text = paste0(
            "Elaboración propia en base a la EPH-INDEC. Universo: ", universo,
            ". Arrastrá horizontalmente para hacer zoom · Click en una serie para mostrarla u ocultarla."
          )
        )
      })

    })
  })
}
