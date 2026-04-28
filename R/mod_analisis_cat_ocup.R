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

      layout_columns(
        col_widths = c(4, 8),
        value_box(
          title = textOutput(ns("pob")),
          value = textOutput(ns("pob_n")),
          showcase = bs_icon("person-badge"),
          p(textOutput(ns("periodo")))
        ),
        card(
          card_body(
            p(em("Tip:"), "Las tarjetas se calculan respecto a la categoría seleccionada en el filtro. La matriz muestra todas las transiciones del panel.")
          )
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
}


# Server del módulo ----------------------------------------------------------

mod_cat_ocup_server <- function(id) {
  moduleServer(id, function(input, output, session) {

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
          df = df_eph_full,
          variables = c("ESTADO", "CAT_OCUP", "PONDERA")
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
          df = df_eph_full,
          variables = c("ESTADO", "CAT_OCUP", "PONDERA")
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
      output$tasa_persistencia <- renderText({ paste0(tasas()$persistencia, "%") })
      output$tasa_salida       <- renderText({ paste0(tasas()$salida, "%") })
      output$tasa_entrada      <- renderText({ paste0(tasas()$entrada, "%") })

      ### Matriz de transición (issue #16 · opción A).
      output$matriz_transicion <- gt::render_gt({
        matriz <- arma_matriz_transicion(
          df_panel = df_eph_panel(),
          var = "CAT_OCUP",
          etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR")
        )
        arma_matriz_transicion_gt(matriz, titulo = NULL)
      })

      output$sankey <- renderHighchart({
        highcharter::hchart(
          object = armo_tabla_sankey(
            table = preparo_base(
              df = df_eph_panel(),
              periodo_base = input$periodo_base,
              var = "CAT_OCUP",
              etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR")),
            categoria = input$category),
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

        df_data <- df_cat_ocup |>
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
          levels_periodo = levels(df_cat_ocup$periodo),
          mostrar_pandemia = input$duo == "todos",
          tick_interval = if (input$duo == "todos") 4 else 1,
          caption_text = "Elaboración propia en base a la EPH-INDEC. Arrastrá horizontalmente para hacer zoom · Click en una serie para mostrarla u ocultarla."
        )
      })

    })
  })
}
