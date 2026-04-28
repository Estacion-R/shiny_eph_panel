#!/usr/bin/env Rscript

### -----------------------------------------------------------------------
### 08-build_tasas_historico.R
###
### Pre-computa el histórico de tasas (Persistencia / Salida / Entrada)
### para los 3 análisis del dashboard. Issue #22.
###
### Outputs:
###   - data_output/tasas_cond_act_historico.csv
###   - data_output/tasas_cat_ocup_historico.csv
###   - data_output/tasas_formalidad_historico.csv
###   - data_output/tasas_formalidad_ampliada_historico.csv
###
### Schema: (periodo, categoria, persistencia, salida, entrada). Mismo
### "periodo" que los CSVs de panel para mantener consistencia.
###
### Costo: ~80 paneles × 4 categorías × 3 tasas = ~1000 cálculos.
### Tarda ~1-2 minutos. Run-once para bootstrap.
### -----------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(glue)
  library(purrr)
  library(eph)
})

source("ETL/99-functions.R")
source("ETL/01-extract.R")        ### df_eph_full con vars derivadas
source("R/utils_analisis.R")       ### arma_tasas_destacadas

cat("Computando histórico de tasas (issue #22)\n\n")

### --- Cond. de actividad -------------------------------------------------
cat(">>> Condición de actividad\n")
tasas_cond <- build_tasas_historico(
  df_microdato = df_eph_full,
  var = "ESTADO",
  etiquetas = c("Ocupado", "Desocupado", "Inactivo")
)
readr::write_csv(tasas_cond, "data_output/tasas_cond_act_historico.csv")
cat("   ", nrow(tasas_cond), "filas escritas\n\n")


### --- Categoría ocupacional ----------------------------------------------
cat(">>> Categoría ocupacional\n")
tasas_cat <- build_tasas_historico(
  df_microdato = df_eph_full,
  var = "CAT_OCUP",
  etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),
  vars_extra = "CAT_OCUP"
)
readr::write_csv(tasas_cat, "data_output/tasas_cat_ocup_historico.csv")
cat("   ", nrow(tasas_cat), "filas escritas\n\n")


### --- Formalidad clásica -------------------------------------------------
cat(">>> Formalidad clásica\n")
tasas_form <- build_tasas_historico(
  df_microdato = df_eph_full,
  var = "formalidad",
  etiquetas = c("Formal", "Informal"),
  vars_extra = c("CAT_OCUP", "PP07H", "formalidad")
)
readr::write_csv(tasas_form, "data_output/tasas_formalidad_historico.csv")
cat("   ", nrow(tasas_form), "filas escritas\n\n")


### --- Formalidad ampliada (solo desde 2023-T4) ---------------------------
cat(">>> Formalidad ampliada (2023-T4+)\n")
tasas_form_amp <- build_tasas_historico(
  df_microdato = df_eph_full,
  var = "formalidad_ampliada",
  etiquetas = c("Formal", "Informal"),
  vars_extra = c("CAT_OCUP", "PP07H", "PP05I", "PP05K", "formalidad_ampliada"),
  desde_panel = "2023-T4"
)
readr::write_csv(tasas_form_amp,
                 "data_output/tasas_formalidad_ampliada_historico.csv")
cat("   ", nrow(tasas_form_amp), "filas escritas\n\n")

cat("Listo.\n")
