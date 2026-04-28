### Helpers compartidos por los módulos de análisis (mod_analisis_*.R).
###
### Extraído como parte de la deuda técnica del epic #11 (issue #12). El
### bloque del line chart estaba copy-pasted en los 3 módulos con ~80
### líneas idénticas. Esta función lo encapsula con parametrización
### mínima, reduciendo el área de duplicación.


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
