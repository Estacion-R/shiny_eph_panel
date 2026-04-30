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

  ### Mapeo de códigos internos a etiquetas legibles para usuario final.
  ### Necesario para que la matriz no muestre "Trab_familiar" o "Patron".
  ### Comparte mapeo base con sankey_label_legible() (sin sufijo (t0)/(t1)).
  legible <- c(
    "Ocupado"       = "Ocupados",
    "Desocupado"    = "Desocupados",
    "Inactivo"      = "Inactivos",
    "Trab_familiar" = "Trab. familiares",
    "Patron"        = "Patrones",
    "Cuenta_propia" = "Cuenta propia",
    "Asalariado"    = "Asalariados",
    "TFSR"          = "Trab. familiares",
    "Formal"        = "Formales",
    "Informal"      = "Informales"
  )
  remap <- function(x) {
    out <- unname(legible[x])
    out[is.na(out)] <- x[is.na(out)]
    out
  }

  df_prep |>
    dplyr::transmute(
      from = remap(stringr::str_replace(ESTADO, "_tant$", "")),
      to   = remap(stringr::str_replace(ESTADO_t1, "_tpost$", "")),
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


### Convierte un código técnico ("Ocupado_t0", "Cuenta_propia_t1", "TFSR_t0")
### en una etiqueta legible para Sankey (issue #25).
###   "Ocupado_t0"        → "Ocupados (t0)"
###   "Cuenta_propia_t1"  → "Cuenta propia (t1)"
###   "TFSR_t0"           → "Trab. familiares (t0)"
###
### Vectorizado: acepta vector char de cualquier largo.
sankey_label_legible <- function(codigos) {
  mapeo <- c(
    "Ocupado"       = "Ocupados",
    "Desocupado"    = "Desocupados",
    "Inactivo"      = "Inactivos",
    "Trab_familiar" = "Trab. familiares",
    "Patron"        = "Patrones",
    "Cuenta_propia" = "Cuenta propia",
    "Asalariado"    = "Asalariados",
    "TFSR"          = "Trab. familiares",
    "Formal"        = "Formales",
    "Informal"      = "Informales"
  )
  base   <- gsub("_t[01]$", "", codigos)
  sufijo <- stringr::str_extract(codigos, "t[01]$")
  legible <- unname(mapeo[base])
  legible[is.na(legible)] <- base[is.na(legible)]  # fallback si no está en el mapeo
  paste0(legible, " (", sufijo, ")")
}


### Banner reactivo de aviso cuando el panel seleccionado cae dentro
### del período de intervención INDEC (ene-2007 a dic-2015). Se muestra
### debajo del filter_query en Foto y Comparar para alertar sobre la
### calidad de los datos sin estorbar el análisis.
###
### @param anios vector numérico con los años de los paneles activos.
###   En Foto pasar 1 año (el del panel). En Comparar pasar 2 años.
### @return div HTML con el aviso, o NULL si ningún año cae en el período.
alerta_intervencion_indec <- function(anios) {
  anios <- suppressWarnings(as.numeric(anios))
  anios <- anios[!is.na(anios)]
  if (length(anios) == 0) return(NULL)
  if (!any(anios >= 2007 & anios <= 2015)) return(NULL)

  shiny::div(
    class = "alert-intervencion-indec",
    shiny::icon("triangle-exclamation"),
    shiny::HTML("&nbsp;Panel del período de "),
    shiny::tags$strong("intervención INDEC (2007-2015)"),
    shiny::HTML(": el propio organismo recomienda leer estos datos "),
    shiny::tags$strong("con reservas"),
    ". ",
    shiny::tags$a(
      "Anexo INDEC 2016 ↗",
      href = "https://www.indec.gob.ar/ftp/cuadros/sociedad/anexo_informe_eph_23_08_16.pdf",
      target = "_blank",
      style = "color:#405BFF; font-weight:600;"
    )
  )
}


### Formatea un delta en puntos porcentuales con flecha y signo (issue #21).
### Ejemplos: 1.2 → "↑ +1.2 pp" / -0.5 → "↓ -0.5 pp" / 0 → "= 0.0 pp".
formato_delta <- function(delta) {
  if (is.null(delta) || length(delta) == 0 || is.na(delta)) {
    return("sin comparación")
  }
  signo <- if (delta > 0.05) "↑ +" else if (delta < -0.05) "↓ " else "= "
  paste0(signo, sprintf("%.1f", delta), " pp")
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
                                       caption_text,
                                       excluir_intervencion = FALSE) {
  ### Excluir período de intervención INDEC (2007-2015) si el usuario
  ### lo pidió. Datos validados oficialmente quedan: 2003-2006 + 2016-actual.
  ### Después del filtro hay que RECALCULAR isExtremo (los extremos del
  ### subset filtrado pueden ser otros) y los min/max del eje Y se
  ### recalculan automáticamente más abajo sobre el df_data filtrado.
  if (isTRUE(excluir_intervencion)) {
    df_data <- df_data |>
      dplyr::filter(!stringr::str_starts(as.character(periodo),
                                         "200[7-9]|201[0-5]")) |>
      dplyr::mutate(isExtremo = (weight == max(weight, na.rm = TRUE)) |
                                (weight == min(weight, na.rm = TRUE)),
                    .by = to)
  }

  ### Highchart con xAxis categórico usa los `unique()` ordenados de los
  ### datos visibles, no los `levels()` del factor. Si filtramos por
  ### dúo trimestral, los períodos exactos como "2007_t1-t2" pueden no
  ### existir en los datos visibles → los plotBands quedan fuera del eje.
  ### Solución: calcular índices sobre los períodos visibles, con
  ### fallback al primer/último trimestre del año si el exacto no está.
  periodos_visibles <- df_data |>
    dplyr::pull(periodo) |>
    unique() |>
    as.character() |>
    sort()

  buscar_idx <- function(periodo_exacto, anio_fallback, lado = "ini") {
    idx <- match(periodo_exacto, periodos_visibles)
    if (!is.na(idx)) return(idx - 1L)
    matches <- grep(paste0("^", anio_fallback, "_"), periodos_visibles)
    if (length(matches) == 0) return(NA_integer_)
    if (lado == "ini") matches[1] - 1L else matches[length(matches)] - 1L
  }

  ### PlotBand pandemia COVID-19 (2020).
  idx_pand_ini <- buscar_idx("2020_t1-t2", "2020", "ini")
  idx_pand_fin <- buscar_idx("2020_t3-t4", "2020", "fin")

  ### PlotBand período de intervención INDEC (issue #20).
  ### El INDEC fue intervenido entre ene-2007 y dic-2015 (decretos 181/15
  ### y 55/16). La advertencia oficial dice que las series de ese período
  ### "deben ser consideradas con reservas". Marcamos con banda gris.
  idx_int_ini <- buscar_idx("2007_t1-t2", "2007", "ini")
  idx_int_fin <- buscar_idx("2015_t4-t1", "2015", "fin")

  plot_bands <- list()

  if (!isTRUE(excluir_intervencion) &&
      !is.na(idx_int_ini) && !is.na(idx_int_fin)) {
    plot_bands <- c(plot_bands, list(list(
      from = idx_int_ini,
      to = idx_int_fin,
      color = "rgba(150, 150, 150, 0.20)",
      label = list(
        text = "Intervención INDEC",
        style = list(color = "#404040", fontWeight = "500",
                     fontSize = "0.85em")
      )
    )))
  }

  if (mostrar_pandemia &&
      !is.na(idx_pand_ini) &&
      !is.na(idx_pand_fin)) {
    plot_bands <- c(plot_bands, list(list(
      from = idx_pand_ini,
      to = idx_pand_fin,
      color = "rgba(234, 255, 56, 0.30)",
      label = list(
        text = "Pandemia COVID-19",
        style = list(color = "#191919", fontWeight = "600")
      )
    )))
  }

  highcharter::hchart(df_data, "areaspline",
                      highcharter::hcaes(periodo, weight, group = to)) |>
    highcharter::hc_add_theme(hc_theme_estacion_r) |>
    ### Paleta diferenciada para line charts con 3+ series (issue #26).
    ### Evita repetir azul (en otro tono también) y mantiene identidad
    ### con azul Estación R como primer color. Naranja y amarillo
    ### Estación R como acentos. Verde como cuarto color.
    highcharter::hc_colors(c("#405BFF", "#FF7043", "#EAFF38", "#7CB342")) |>
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
      gridLineDashStyle = "Dot",
      ### Eje Y anclado al min/max real de la serie con padding del 15%
      ### del rango (mínimo 1 pp). Esto evita que el punto más bajo o
      ### más alto quede pegado al borde. Clamp a 0-100 para respetar
      ### los límites naturales del porcentaje.
      min = local({
        rng <- range(df_data$weight, na.rm = TRUE)
        if (any(is.infinite(rng))) return(0)
        pad <- max(1, (rng[2] - rng[1]) * 0.15)
        max(0, rng[1] - pad)
      }),
      max = local({
        rng <- range(df_data$weight, na.rm = TRUE)
        if (any(is.infinite(rng))) return(100)
        pad <- max(1, (rng[2] - rng[1]) * 0.15)
        min(100, rng[2] + pad)
      })
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
    highcharter::hc_caption(
      useHTML = TRUE,
      text = paste0(
        caption_text,
        ### Nota metodológica de intervención INDEC (issue #20). Solo si
        ### el período cubierto incluye 2007-2015.
        if (isTRUE(excluir_intervencion)) {
          " · <span style='color:#404040'>Período 2007-2015 excluido (intervención INDEC).</span>"
        } else if (!is.na(idx_int_ini) && !is.na(idx_int_fin)) {
          paste0(
            " · <span style='color:#404040'>Series 2007-2015: período de intervención INDEC, leer con reservas ",
            "(<a href='https://www.indec.gob.ar/ftp/cuadros/sociedad/anexo_informe_eph_23_08_16.pdf' ",
            "target='_blank' style='color:#405BFF'>anexo INDEC 2016</a>).</span>"
          )
        } else {
          ""
        }
      )
    )
}
