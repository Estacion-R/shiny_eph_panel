#!/usr/bin/env Rscript

### -----------------------------------------------------------------------
### 05-build_panel_cat_ocup.R
###
### Pre-computa el histórico de movilidad entre Categorías ocupacionales
### (CAT_OCUP) para todos los paneles disponibles. Output:
###   data_output/panel_cat_ocup_historico.csv
###
### Mismo patrón que panel_cond_act_historico.csv pero panelizando CAT_OCUP
### en lugar de ESTADO. Filtra implícitamente a Ocupados porque CAT_OCUP
### solo está definida (1..4) para personas con ESTADO == 1.
###
### Run-once: lo usamos en Fase 3 (#9) para bootstrappear el dataset.
### El workflow mensual (03-update_data.R) deberá replicar esta lógica
### para mantener actualizado el histórico cuando lleguen trimestres
### nuevos. TODO: integrar al workflow.
### -----------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(glue)
  library(purrr)
  library(eph)
})

source("ETL/99-functions.R")

cat("Cargando microdato...\n")
df_eph_full <- arrow::read_parquet("data_raw/df_eph.parquet")

### Trimestres con datos
periodos <- df_eph_full |>
  distinct(ANO4, TRIMESTRE) |>
  arrange(ANO4, TRIMESTRE)

### Paneles armables = trimestre que tiene su consecutivo
paneles <- periodos |>
  mutate(
    anio_post = if_else(TRIMESTRE %in% 1:3, ANO4, ANO4 + 1L),
    trim_post = if_else(TRIMESTRE %in% 1:3, TRIMESTRE + 1L, 1L),
    tiene_post = paste(anio_post, trim_post) %in%
      paste(df_eph_full$ANO4, df_eph_full$TRIMESTRE)
  ) |>
  filter(tiene_post) |>
  mutate(periodo = glue("{ANO4}_t{TRIMESTRE}-t{trim_post}"))

cat("Paneles a computar:", nrow(paneles), "\n\n")

### Etiquetas de CAT_OCUP (códigos 1..4)
etiquetas_cat_ocup <- c("Patron", "Cuenta_propia", "Asalariado", "TFSR")
categorias_sankey  <- etiquetas_cat_ocup  ### las 4 producen una vista del Sankey

paneles_nuevos <- paneles |>
  pmap_dfr(function(ANO4, TRIMESTRE, anio_post, trim_post, periodo, ...) {
    cat(glue("  panel {periodo}... "))

    df_panel <- armo_base_panel(
      anio_0 = ANO4, trimestre_0 = TRIMESTRE,
      anio_1 = anio_post, trimestre_1 = trim_post,
      df = df_eph_full,
      variables = c("ESTADO", "CAT_OCUP", "PONDERA")
    )

    df_prep <- preparo_base(
      df = df_panel,
      periodo_base = "t_anterior",
      var = "CAT_OCUP",
      etiquetas = etiquetas_cat_ocup
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

path_out <- "data_output/panel_cat_ocup_historico.csv"
readr::write_csv(paneles_nuevos, path_out)

cat("Escrito:", path_out, "\n")
cat("Tamaño:", round(file.info(path_out)$size / 1024, 1), "KB\n")
