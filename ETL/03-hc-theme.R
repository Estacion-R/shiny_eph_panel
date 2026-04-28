# Tema Highcharts oficial Estación R.
# Sincronizado con _brand.yml (paleta y tipografía Ubuntu).
# Aplicar en cada hchart con: hc_add_theme(hc_theme_estacion_r)

hc_theme_estacion_r <- highcharter::hc_theme(
  colors = c("#405BFF", "#EAFF38", "#1839F4", "#191919", "#7F7FFF", "#F7F7F7"),
  chart = list(
    style           = list(fontFamily = "Ubuntu, sans-serif"),
    backgroundColor = "transparent"
  ),
  title    = list(style = list(color = "#191919", fontWeight = "500")),
  subtitle = list(style = list(color = "#191919")),
  caption  = list(style = list(color = "#191919")),
  xAxis = list(
    labels    = list(style = list(fontFamily = "Ubuntu", color = "#191919")),
    lineColor = "#191919",
    tickColor = "#191919"
  ),
  yAxis = list(
    labels        = list(style = list(fontFamily = "Ubuntu", color = "#191919")),
    gridLineColor = "#F7F7F7"
  ),
  tooltip = list(
    backgroundColor = "#FFFFFF",
    borderColor     = "#405BFF",
    borderWidth     = 1,
    style           = list(fontFamily = "Ubuntu", color = "#191919")
  ),
  legend = list(
    itemStyle = list(fontFamily = "Ubuntu", color = "#191919")
  ),
  plotOptions = list(
    series = list(
      marker = list(lineColor = "#FFFFFF", lineWidth = 1)
    )
  )
)
