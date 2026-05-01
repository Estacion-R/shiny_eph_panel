#!/usr/bin/env Rscript

### -----------------------------------------------------------------------
### 10-build_calidad_panel.R
###
### Pre-computa el histórico de calidad del panel: para cada dúo trimestral
### (t0 → t1), cuántas personas de la muestra t0 aparecen también en t1
### (panel matched), tanto en filas como ponderado.
###
### Output: data_output/calidad_panel_pct_historico.csv
###
### Mismo patrón idempotente que panel_*_historico.csv: la función vive
### en 99-functions.R (regenerar_calidad_panel) y se llama acá para el
### bootstrap inicial. Después, ETL/03-update_data.R la invoca cada vez
### que llegan trimestres nuevos.
###
### Run-once (bootstrap):
###   Rscript ETL/10-build_calidad_panel.R
### -----------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(eph)
  library(glue)
  library(purrr)
  library(readr)
  library(tibble)
})

source("ETL/99-functions.R")

cat("Cargando microdato...\n")
df_eph_full <- arrow::read_parquet("data_raw/df_eph.parquet")

regenerar_calidad_panel(
  path_csv     = "data_output/calidad_panel_pct_historico.csv",
  df_microdato = df_eph_full
)

cat("Listo.\n")
