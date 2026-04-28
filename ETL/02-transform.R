### Componentes UI y prep de datos del histórico.
### Las librerías shiny/dplyr/imola/markdown ya vienen cargadas desde 00-libraries.R
### + el bloque de imola/markdown.
library(imola)
library(markdown)


### Preparo base df_cond_act: ordeno períodos como factor cronológico real.
### Los IDs vienen en formato "YYYY_tN-tM" (ej: "2003_t4-t1", "2020_t1-t2").
### Parseo año + trimestre inicial para ordenar correctamente.
periodo_categ <- df_cond_act |>
  dplyr::distinct(periodo) |>
  dplyr::mutate(
    anio = as.integer(stringr::str_extract(periodo, "^[0-9]{4}")),
    trim_ini = as.integer(stringr::str_extract(periodo, "(?<=_t)[0-9]"))
  ) |>
  dplyr::arrange(anio, trim_ini) |>
  dplyr::pull(periodo)

df_cond_act <- df_cond_act |>
  mutate(periodo = factor(periodo, levels = periodo_categ))


### -----------------------------------------------------------------------
### Filtros para gráfico de flujo (Sankey - pestaña "Foto")
### -----------------------------------------------------------------------

filter_sankey_anio_ant <- selectInput(inputId = "anio_ant",
                                      label = "Año del panel",
                                      choices = anios_disponibles,
                                      selected = anio_max_disponible
)

### Duos válidos para el año por defecto (último disponible). Se recalculan
### dinámicamente en el server cuando cambia el año seleccionado.
duos_iniciales <- duos_disponibles_por_anio(anio_max_disponible, periodos_disponibles)

filter_sankey_trim_ant <- selectInput(inputId = "trimestre_ant",
                                      label = "Panel (trimestres consecutivos)",
                                      choices = duos_iniciales,
                                      selected = duos_iniciales[1]
)

filter_sankey_categoria <- selectInput(inputId = "category",
                                       label = "Categoría de base (el 100%)",
                                       choices = c("Ocupado", "Desocupado", "Inactivo")
)

filter_sankey_periodo_base <- selectInput(inputId = "periodo_base",
                                          label = "Sentido (trimestre base)",
                                          choices = c("Trimestre anterior" = "t_anterior",
                                                      "Trimestre posterior" = "t_posterior")
)


filters_sankey <- list(
  filter_sankey_anio_ant,
  filter_sankey_categoria,
  filter_sankey_periodo_base,
  filter_sankey_trim_ant
)


### Application dependencies (CSS/JS estáticos)
include_styles <- tags$head(
  tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
  tags$script(src = "script.js"),
  tags$script(src = "highlight.min.js"),
  tags$script("hljs.highlightAll();"),
  tags$link(href = "a11y-dark.min.css", rel = "stylesheet")
)

### Helpers de UI: filtros tipo "Natural Language Query" donde los selectInput
### se intercalan dentro de una oración.
filter_preposition <- function(prefix_text, input, suffix_text) {
  div(
    class = "filter-preposition",
    tags$span(class = "preposition-affix", prefix_text),
    input,
    tags$span(class = "preposition-affix", suffix_text)
  )
}

filter_query <- function(prefix_text = "", ..., suffix_text = "") {
  div(
    class = "filter-query nlq-styling",
    tags$span(class = "preposition-affix", prefix_text),
    ...,
    tags$span(class = "preposition-affix", suffix_text)
  )
}


filters <- filter_query(
  prefix_text = "",

  filter_preposition(
    "Conocer el",
    selectInput(inputId = "periodo_base",
                label = "Sentido (trimestre base)",
                choices = c("destino" = "t_anterior",
                            "origen" = "t_posterior")),
    ""
  ),

  filter_preposition(
    prefix_text = "de los",
    input = selectInput(inputId = "category",
                        label = "Categoría de base (el 100%)",
                        choices = c("Ocupados" = "Ocupado",
                                    "Desocupados" = "Desocupado",
                                    "Inactivos" = "Inactivo")),
    suffix_text = ""
  ),

  filter_preposition(
    "para el año",
    selectInput(inputId = "anio_ant",
                label = "Año del panel",
                choices = anios_disponibles,
                selected = anio_max_disponible
    ),
    ""
  ),

  filter_preposition(
    "entre los trimestres",
    selectInput(inputId = "trimestre_ant",
                label = "Panel (trimestres consecutivos)",
                choices = duos_iniciales,
                selected = duos_iniciales[1]
    ),
    ""
  ),
  suffix_text = ""
)


### -----------------------------------------------------------------------
### Filtros para gráfico de línea (pestaña "Película")
### -----------------------------------------------------------------------

filter_line_desde <- selectInput(inputId = "desde",
                                 label = "Desde",
                                 choices = c("Ocupación" = "Ocupado_t0",
                                             "Desocupación" = "Desocupado_t0",
                                             "Inactividad" = "Inactivo_t0"),
                                 selected = "Desocupado_t0"
)

filter_line_hacia <- selectInput(inputId = "hacia",
                                 label = "Hacia",
                                 choices = c("Ocupación" = "Ocupado_t1",
                                             "Desocupación" = "Desocupado_t1",
                                             "Inactividad" = "Inactivo_t1"),
                                 selected = "Ocupado_t1",
                                 multiple = TRUE
)

### Filtro de dúo trimestral: por default muestra todos los duos (serie completa).
### Si se elige uno específico (ej: t1-t2), filtra el data al sufijo correspondiente
### permitiendo comparar el mismo dúo año a año (peras con peras).
filter_line_duo <- selectInput(inputId = "duo",
                               label = "Trimestres",
                               choices = c("Todos los trimestres" = "todos",
                                           "1-2" = "t1-t2",
                                           "2-3" = "t2-t3",
                                           "3-4" = "t3-t4",
                                           "4-1" = "t4-t1"),
                               selected = "todos"
)

filters_line <- filter_query(
  prefix_text = "",
  filter_preposition("Mostrar el flujo desde la", filter_line_desde, ""),
  filter_preposition("hacia", filter_line_hacia, ""),
  filter_preposition("en los trimestres", filter_line_duo, ""),
  suffix_text = ""
)
