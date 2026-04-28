### Componentes UI compartidos y prep de datos del histórico.
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


### Application dependencies (CSS/JS estáticos)
include_styles <- tags$head(
  tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
  tags$script(src = "script.js"),
  tags$script(src = "highlight.min.js"),
  tags$script("hljs.highlightAll();"),
  tags$link(href = "a11y-dark.min.css", rel = "stylesheet")
)

### Helpers de UI: filtros tipo "Natural Language Query" donde los selectInput
### se intercalan dentro de una oración. Los módulos en R/ los reusan armando
### sus propias oraciones con IDs namespaced via NS(id).
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
