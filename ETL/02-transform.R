### Componentes UI y prep de datos del histórico.
### Las librerías shiny/dplyr/imola/markdown ya vienen cargadas desde 00-libraries.R
### + el bloque de imola/markdown.
library(imola)
library(markdown)


### Preparo base df_cond_act: ordeno períodos como factor para que el line chart
### respete el orden cronológico.
periodo_categ <- unique(df_cond_act$periodo)

df_cond_act <- df_cond_act |>
  mutate(periodo = factor(periodo, level = periodo_categ))


### -----------------------------------------------------------------------
### Filtros para gráfico de flujo (Sankey - pestaña "Foto")
### -----------------------------------------------------------------------

filter_sankey_anio_ant <- selectInput(inputId = "anio_ant",
                                      label = "Año del panel",
                                      choices = anios_disponibles,
                                      selected = anio_max_disponible
)

filter_sankey_trim_ant <- selectInput(inputId = "trimestre_ant",
                                      label = "Panel (trimestres consecutivos)",
                                      choices = c("1-2" = 1, "2-3" = 2, "3-4" = 3, "4-1" = 4),
                                      selected = 1
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
    class = "default-styling filter-query",
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
    suffix_text = "    ,"
  ),

  filter_preposition(
    ", para el año",
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
                choices = c("1-2" = 1, "2-3" = 2, "3-4" = 3, "4-1" = 4),
                selected = 1
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

filters_line <- list(
  filter_line_desde,
  filter_line_hacia
)
