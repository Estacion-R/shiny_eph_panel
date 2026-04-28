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
      layout_columns(
        col_widths = c(4, 8),
        value_box(
          title = textOutput(ns("pob")),
          value = textOutput(ns("pob_n")),
          showcase = bs_icon("person-badge"),
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
        ### Plotband pandemia solo cuando se ven todos los duos.
        mostrar_pandemia <- input$duo == "todos"
        idx_pandemia_ini <- match("2020_t1-t2", levels(df_cat_ocup$periodo)) - 1
        idx_pandemia_fin <- match("2020_t3-t4", levels(df_cat_ocup$periodo)) - 1

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

        tick_interval <- if (input$duo == "todos") 4 else 1

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

        hchart(df_cat_ocup |>
                 filter(from == input$desde, to %in% input$hacia) |>
                 filter(input$duo == "todos" |
                          stringr::str_ends(as.character(periodo), input$duo)) |>
                 arrange(periodo) |>
                 mutate(to = purrr::map2_chr(from, to, etiqueta_serie),
                        id = stringr::str_replace_all(id, "tant", "t0"),
                        id = stringr::str_replace_all(id, "tpost", "t2")),
               "areaspline",
               hcaes(periodo, weight, group = to)) |>
          hc_add_theme(hc_theme_estacion_r) |>
          hc_chart(zoomType = "x") |>
          hc_plotOptions(
            areaspline = list(
              fillOpacity = 0.18,
              lineWidth = 2.5,
              marker = list(enabled = FALSE,
                            states = list(hover = list(enabled = TRUE, radius = 5)))
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
          hc_legend(align = "center", verticalAlign = "top", layout = "horizontal") |>
          hc_caption(
            text = "Elaboración propia en base a la EPH-INDEC. Arrastrá horizontalmente para hacer zoom."
          )
      })

    })
  })
}
