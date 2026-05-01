### Componentes UI compartidos y prep de datos del histórico.
### Las librerías shiny/dplyr ya vienen cargadas desde 00-libraries.R.


### Helper: ordena períodos cronológicamente como factor.
### Los IDs vienen en formato "YYYY_tN-tM" (ej: "2003_t4-t1", "2020_t1-t2").
### Parseo año + trimestre inicial para ordenar correctamente.
ordenar_periodo_cronologico <- function(df) {
  niveles <- df |>
    dplyr::distinct(periodo) |>
    dplyr::mutate(
      anio = as.integer(stringr::str_extract(periodo, "^[0-9]{4}")),
      trim_ini = as.integer(stringr::str_extract(periodo, "(?<=_t)[0-9]"))
    ) |>
    dplyr::arrange(anio, trim_ini) |>
    dplyr::pull(periodo)

  df |> mutate(periodo = factor(periodo, levels = niveles))
}

df_cond_act   <- ordenar_periodo_cronologico(df_cond_act)
df_cat_ocup   <- ordenar_periodo_cronologico(df_cat_ocup)
df_formalidad <- ordenar_periodo_cronologico(df_formalidad)
### df_formalidad_ampliada puede estar vacía si el bootstrap aún no se corrió.
if (nrow(df_formalidad_ampliada) > 0) {
  df_formalidad_ampliada <- ordenar_periodo_cronologico(df_formalidad_ampliada)
}

### Históricos de tasas (issue #22). Mismo factor cronológico.
if (nrow(df_tasas_cond_act) > 0) {
  df_tasas_cond_act <- ordenar_periodo_cronologico(df_tasas_cond_act)
}
if (nrow(df_tasas_cat_ocup) > 0) {
  df_tasas_cat_ocup <- ordenar_periodo_cronologico(df_tasas_cat_ocup)
}
if (nrow(df_tasas_formalidad) > 0) {
  df_tasas_formalidad <- ordenar_periodo_cronologico(df_tasas_formalidad)
}
if (nrow(df_tasas_formalidad_amp) > 0) {
  df_tasas_formalidad_amp <- ordenar_periodo_cronologico(df_tasas_formalidad_amp)
}


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
