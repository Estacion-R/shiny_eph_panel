### Helpers compartidos por los módulos de análisis (mod_analisis_*.R).
###
### Extraído como parte de la deuda técnica del epic #11 (issue #12). El
### bloque del line chart estaba copy-pasted en los 3 módulos con ~80
### líneas idénticas. Esta función lo encapsula con parametrización
### mínima, reduciendo el área de duplicación.


### Construye una matriz de transición NxN a partir de un panel preparado
### por preparo_base(). Output: tibble con `from` como primera col y una
### col por categoría destino con el porcentaje.
###
### @param df_panel microdato del panel (output de armo_base_panel).
### @param var nombre de la columna a panelizar.
### @param etiquetas vector char con las etiquetas de los códigos 1..N.
arma_matriz_transicion <- function(df_panel, var, etiquetas) {
  df_prep <- preparo_base(df_panel,
                          periodo_base = "t_anterior",
                          var = var,
                          etiquetas = etiquetas)

  df_prep |>
    dplyr::transmute(
      from = stringr::str_replace(ESTADO, "_tant$", ""),
      to   = stringr::str_replace(ESTADO_t1, "_tpost$", ""),
      porc = porc_base
    ) |>
    tidyr::pivot_wider(names_from = to, values_from = porc, values_fill = 0)
}


### Renderiza la matriz de transición como tabla gt con paleta de calor.
arma_matriz_transicion_gt <- function(matriz_df, titulo = "Matriz de transición") {
  cols_destino <- setdiff(names(matriz_df), "from")

  gt::gt(matriz_df, rowname_col = "from") |>
    gt::tab_header(title = titulo,
                   subtitle = "Porcentaje de transición t0 → t1") |>
    gt::fmt_number(columns = dplyr::all_of(cols_destino),
                   decimals = 1, suffix = "%") |>
    gt::data_color(
      columns = dplyr::all_of(cols_destino),
      palette = c("#FFFFFF", "#A8B6FF", "#405BFF"),
      na_color = "#F7F7F7"
    ) |>
    gt::tab_options(
      table.font.names = "Ubuntu, sans-serif",
      heading.title.font.size = "1em",
      heading.subtitle.font.size = "0.8em",
      table.font.size = "0.85em"
    ) |>
    gt::tab_style(
      style = gt::cell_text(weight = "600"),
      locations = gt::cells_stub()
    )
}


### Calcula las 3 tasas destacadas para tarjetas de Foto:
###   - persistencia: % de la categoría seleccionada que sigue en t1.
###   - salida: % de la seleccionada que cambia (100 - persistencia).
###   - entrada: % de la categoría seleccionada en t1 que vino de otra.
###
### Devuelve list(persistencia, salida, entrada).
arma_tasas_destacadas <- function(df_panel, var, etiquetas, categoria) {
  ### Tasa de persistencia y salida (calculadas con periodo_base="t_anterior":
  ### porc_base se calcula sobre el total t0 de la categoría).
  df_t_ant <- preparo_base(df_panel, "t_anterior", var, etiquetas)

  persistencia <- df_t_ant |>
    dplyr::filter(ESTADO == paste0(categoria, "_tant"),
                  ESTADO_t1 == paste0(categoria, "_tpost")) |>
    dplyr::pull(porc_base)

  if (length(persistencia) == 0) persistencia <- 0
  salida <- 100 - persistencia

  ### Tasa de entrada (con periodo_base="t_posterior": porc_base sobre el
  ### total t1 de la categoría → quienes son cat_t1 desde otra cat_t0).
  df_t_post <- preparo_base(df_panel, "t_posterior", var, etiquetas)

  entrada_misma <- df_t_post |>
    dplyr::filter(ESTADO_t1 == paste0(categoria, "_tpost"),
                  ESTADO == paste0(categoria, "_tant")) |>
    dplyr::pull(porc_base)

  if (length(entrada_misma) == 0) entrada_misma <- 0
  entrada <- 100 - entrada_misma  ### % en t1 que NO estaba en t0

  list(
    persistencia = round(persistencia, 1),
    salida = round(salida, 1),
    entrada = round(entrada, 1)
  )
}


### Construye el highchart areaspline para la pestaña Película de
### cualquier análisis de panel.
###
### @param df_data tibble con columnas (periodo, weight, to, isExtremo).
###   `to` debe contener el label legible de la serie (ej: "% de
###   Asalariados que pasan a Cuenta propia"). `isExtremo` flag
###   bool por punto para los dataLabels.
### @param levels_periodo vector de niveles del factor periodo (para
###   ubicar el plotBand de pandemia por índice 0-based).
### @param mostrar_pandemia bool. TRUE muestra el plotBand amarillo en
###   2020-T1 a 2020-T3-T4.
### @param tick_interval entero. Cada cuántas etiquetas mostrar en eje X.
### @param caption_text texto del caption (incluye fuente y notas
###   metodológicas).
arma_line_chart_areaspline <- function(df_data,
                                       levels_periodo,
                                       mostrar_pandemia = TRUE,
                                       tick_interval = 4,
                                       caption_text) {
  idx_pand_ini <- match("2020_t1-t2", levels_periodo) - 1
  idx_pand_fin <- match("2020_t3-t4", levels_periodo) - 1

  plot_bands <- if (mostrar_pandemia &&
                    !is.na(idx_pand_ini) &&
                    !is.na(idx_pand_fin)) {
    list(list(
      from = idx_pand_ini,
      to = idx_pand_fin,
      color = "rgba(234, 255, 56, 0.30)",
      label = list(
        text = "Pandemia COVID-19",
        style = list(color = "#191919", fontWeight = "600")
      )
    ))
  } else {
    list()
  }

  highcharter::hchart(df_data, "areaspline",
                      highcharter::hcaes(periodo, weight, group = to)) |>
    highcharter::hc_add_theme(hc_theme_estacion_r) |>
    highcharter::hc_chart(zoomType = "x") |>
    highcharter::hc_plotOptions(
      areaspline = list(
        fillOpacity = 0.18,
        lineWidth = 2.5,
        marker = list(enabled = FALSE,
                      states = list(hover = list(enabled = TRUE, radius = 5))),
        dataLabels = list(
          enabled = TRUE,
          filter = list(property = "isExtremo", operator = "==", value = TRUE),
          format = "{point.y}%",
          style = list(fontSize = "0.75em",
                       textOutline = "2px white",
                       color = "#191919",
                       fontWeight = "600")
        )
      )
    ) |>
    highcharter::hc_xAxis(
      title = list(text = NULL),
      tickInterval = tick_interval,
      plotBands = plot_bands,
      labels = list(rotation = -45, style = list(fontSize = "0.85em"))
    ) |>
    highcharter::hc_yAxis(
      title = list(text = "% del total"),
      labels = list(format = "{value}%"),
      gridLineDashStyle = "Dot"
    ) |>
    highcharter::hc_tooltip(
      shared = TRUE,
      useHTML = TRUE,
      headerFormat = "<span style='font-size: 0.9em; color: #191919;'><b>{point.key}</b></span><br/>",
      pointFormat = "<span style='color: {series.color}'>●</span> {series.name}: <b>{point.y}%</b><br/>",
      backgroundColor = "rgba(255,255,255,0.96)",
      borderColor = "#405BFF",
      borderRadius = 6
    ) |>
    highcharter::hc_legend(
      align = "center", verticalAlign = "top", layout = "horizontal",
      itemStyle = list(cursor = "pointer", fontWeight = "500")
    ) |>
    highcharter::hc_caption(text = caption_text)
}
