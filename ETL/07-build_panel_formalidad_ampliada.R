#!/usr/bin/env Rscript

### -----------------------------------------------------------------------
### 07-build_panel_formalidad_ampliada.R
###
### Pre-computa el histórico de movilidad Formal ↔ Informal usando la
### definición AMPLIADA (issue #15), alineada con la Resolución I de la
### 21° CIET (OIT 2023). Output:
###   data_output/panel_formalidad_ampliada_historico.csv
###
### Universo: ocupados (CAT_OCUP en 1..4). La variable derivada
### `formalidad_ampliada` se computa en 01-extract.R.
###
### Cobertura temporal: solo desde 4T 2023 (cuando EPH agregó PP05I/K).
### Trimestres pre-2023 quedan filtrados por preparo_base() porque
### formalidad_ampliada == NA.
###
### Run-once: issue #15.
### -----------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(glue)
  library(purrr)
  library(eph)
})

source("ETL/99-functions.R")
source("ETL/01-extract.R")  ### usa df_eph_full con formalidad_ampliada

cat("Computando histórico de Formal/Informal AMPLIADA\n\n")

### Solo paneles desde 2023-T4 en adelante (donde formalidad_ampliada
### tiene valores no-NA por la disponibilidad de PP05I/K).
paneles <- periodos_disponibles |>
  mutate(
    anio_post = if_else(TRIMESTRE %in% 1:3, ANO4, ANO4 + 1L),
    trim_post = if_else(TRIMESTRE %in% 1:3, TRIMESTRE + 1L, 1L),
    tiene_post = paste(anio_post, trim_post) %in%
      paste(periodos_disponibles$ANO4, periodos_disponibles$TRIMESTRE)
  ) |>
  filter(tiene_post) |>
  filter(ANO4 > 2023 | (ANO4 == 2023 & TRIMESTRE >= 4)) |>
  mutate(periodo = glue("{ANO4}_t{TRIMESTRE}-t{trim_post}"))

cat("Paneles a computar:", nrow(paneles), "\n\n")

etiquetas_formalidad <- c("Formal", "Informal")
categorias_sankey   <- etiquetas_formalidad

paneles_nuevos <- paneles |>
  pmap_dfr(function(ANO4, TRIMESTRE, anio_post, trim_post, periodo, ...) {
    cat(glue("  panel {periodo}... "))

    df_panel <- armo_base_panel(
      anio_0 = ANO4, trimestre_0 = TRIMESTRE,
      anio_1 = anio_post, trimestre_1 = trim_post,
      df = df_eph_full,
      variables = c("ESTADO", "CAT_OCUP", "PP07H", "PP05I", "PP05K",
                    "formalidad_ampliada", "PONDERA")
    )

    df_prep <- preparo_base(
      df = df_panel,
      periodo_base = "t_anterior",
      var = "formalidad_ampliada",
      etiquetas = etiquetas_formalidad
    )

    res <- map_dfr(categorias_sankey, function(cat) {
      tryCatch({
        armo_tabla_sankey(table = df_prep, categoria = cat) |>
          mutate(periodo = as.character(periodo))
      }, error = function(e) tibble())
    })

    cat(nrow(res), "filas\n")
    res
  })

cat("\nFilas totales:", nrow(paneles_nuevos), "\n")

path_out <- "data_output/panel_formalidad_ampliada_historico.csv"
readr::write_csv(paneles_nuevos, path_out)

cat("Escrito:", path_out, "\n")
cat("Tamaño:", round(file.info(path_out)$size / 1024, 1), "KB\n")
