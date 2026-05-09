#!/usr/bin/env Rscript

### -----------------------------------------------------------------------
### 06-build_panel_formalidad.R
###
### Pre-computa el histórico de movilidad entre asalariados Formales e
### Informales (definición clásica EPH vía PP07H) para todos los paneles
### disponibles. Output:
###   data_output/panel_formalidad_historico.csv
###
### Universo: solo asalariados (CAT_OCUP = 3). La variable derivada
### `formalidad` se computa en 01-extract.R.
###   - 1 = Formal (PP07H = 1, con aportes)
###   - 2 = Informal (PP07H = 2, sin aportes)
###   - NA para no-asalariados (filtrado por preparo_base).
###
### Run-once: Fase 4 del epic #6 (issue #10).
### -----------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(glue)
  library(purrr)
  library(eph)
})

source("ETL/99-functions.R")
source("ETL/01-extract.R")  ### usa df_eph_full con la variable derivada `formalidad`

cat("Computando histórico de Formal/Informal\n\n")

paneles <- periodos_disponibles |>
  mutate(
    anio_post = if_else(TRIMESTRE %in% 1:3, ANO4, ANO4 + 1L),
    trim_post = if_else(TRIMESTRE %in% 1:3, TRIMESTRE + 1L, 1L),
    tiene_post = paste(anio_post, trim_post) %in%
      paste(periodos_disponibles$ANO4, periodos_disponibles$TRIMESTRE)
  ) |>
  filter(tiene_post) |>
  mutate(periodo = glue("{ANO4}_t{TRIMESTRE}-t{trim_post}"))

cat("Paneles a computar:", nrow(paneles), "\n\n")

etiquetas_formalidad <- c("Formal", "Informal")
categorias_sankey   <- etiquetas_formalidad

paneles_nuevos <- paneles |>
  pmap(function(ANO4, TRIMESTRE, anio_post, trim_post, periodo, ...) {
    cat(glue("  panel {periodo}... "))

    df_panel <- armo_base_panel(
      anio_0 = ANO4, trimestre_0 = TRIMESTRE,
      anio_1 = anio_post, trimestre_1 = trim_post,
      df = df_eph_full,
      variables = c("ESTADO", "CAT_OCUP", "PP07H", "formalidad", "PONDERA")
    )

    df_prep <- preparo_base(
      df = df_panel,
      periodo_base = "t_anterior",
      var = "formalidad",
      etiquetas = etiquetas_formalidad
    )

    res <- map(categorias_sankey, function(cat) {
      tryCatch({
        armo_tabla_sankey(table = df_prep, categoria = cat) |>
          mutate(periodo = as.character(periodo))
      }, error = function(e) tibble())
    }) |>
      list_rbind()

    cat(nrow(res), "filas\n")
    res
  }) |>
  list_rbind()

cat("\nFilas totales:", nrow(paneles_nuevos), "\n")

path_out <- "data_output/panel_formalidad_historico.csv"
readr::write_csv(paneles_nuevos, path_out)

cat("Escrito:", path_out, "\n")
cat("Tamaño:", round(file.info(path_out)$size / 1024, 1), "KB\n")
