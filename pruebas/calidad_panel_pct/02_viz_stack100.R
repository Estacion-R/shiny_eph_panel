### -----------------------------------------------------------------------
### Prototipo issue #36 — paso 2: viz histórica del % de personas-panel
### encontradas. Iteración 2: barras simples con eje Y acotado a 50%
### (tope teórico del esquema 2-2-2). El stacked al 100% se descartó
### porque el complemento "no encontrado" es por diseño, no por atrición.
###
### Output:
###   pruebas/calidad_panel_pct/output/pct_encontrado_stack100.html
###
### Corre desde la raíz del proyecto, después de 01_compute_pct.R:
###   source("pruebas/calidad_panel_pct/02_viz_stack100.R")
### -----------------------------------------------------------------------

source("ETL/00-libraries.R")
source("ETL/03-hc-theme.R")

library(readr)
library(htmlwidgets)

historico_pct <- read_csv(
  "pruebas/calidad_panel_pct/output/pct_encontrado_historico.csv",
  show_col_types = FALSE
) |>
  arrange(anio_0, trim_0) |>
  mutate(periodo = factor(periodo, levels = periodo))

### Versión interactiva (Highcharts) — encaja con el resto de la app.
### El eje Y va de 0 a 50% porque por el esquema 2-2-2 el máximo teórico
### de personas pareables entre t0 y t1 es la mitad de la muestra.
hc_viz <- highchart() |>
  hc_chart(type = "column") |>
  hc_plotOptions(
    column = list(
      borderWidth  = 0,
      groupPadding = 0.05,
      pointPadding = 0.02
    )
  ) |>
  hc_xAxis(
    categories = as.character(historico_pct$periodo),
    title      = list(text = "Par trimestral (t0 → t1)"),
    labels     = list(rotation = -45, step = 2)
  ) |>
  hc_yAxis(
    title       = list(text = "% sobre la muestra del t0"),
    min         = 0,
    max         = 50,
    labels      = list(format = "{value}%"),
    plotLines   = list(list(
      value     = 50,
      color     = "#191919",
      width     = 1,
      dashStyle = "Dash",
      zIndex    = 5,
      label     = list(
        text   = "Tope teórico 50% (esquema 2-2-2)",
        align  = "right",
        x      = -10,
        style  = list(color = "#191919", fontFamily = "Ubuntu",
                      fontSize = "0.8em")
      )
    ))
  ) |>
  hc_tooltip(
    headerFormat = "<b>{point.key}</b><br>",
    pointFormat  = paste0(
      "<span style=\"color:{series.color}\">●</span> ",
      "{series.name}: <b>{point.y}%</b>"
    )
  ) |>
  hc_add_series(
    name           = "Encontradas en panel",
    data           = historico_pct$pct_encontrado_n,
    color          = "#405BFF",
    showInLegend   = FALSE
  ) |>
  hc_title(text = "% de personas-panel encontradas por par trimestral") |>
  hc_subtitle(text = paste(
    "EPH-INDEC. Universo: personas con ESTADO ∈ 1..4 en el t0.",
    "Por el esquema 2-2-2, el máximo teórico es 50%."
  )) |>
  hc_caption(text = "Fuente: elaboración propia sobre microdatos EPH (paquete eph).") |>
  hc_credits(enabled = FALSE) |>
  hc_add_theme(hc_theme_estacion_r)

dir.create("pruebas/calidad_panel_pct/output", showWarnings = FALSE,
           recursive = TRUE)

saveWidget(hc_viz,
           "pruebas/calidad_panel_pct/output/pct_encontrado_stack100.html",
           selfcontained = TRUE)

cat("Listo. Output:\n")
cat("  pruebas/calidad_panel_pct/output/pct_encontrado_stack100.html\n")
