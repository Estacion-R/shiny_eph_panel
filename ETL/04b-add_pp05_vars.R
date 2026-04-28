#!/usr/bin/env Rscript

### -----------------------------------------------------------------------
### 04b-add_pp05_vars.R
###
### Approach pragmático para sumar PP05I y PP05K al parquet sin re-descargar
### todos los trimestres. Útil cuando vars nuevas solo existen en períodos
### recientes (issue #15: PP05I/K disponibles desde 4T 2023).
###
### Lógica:
###   1. Lee parquet actual (sin PP05I/K).
###   2. Inicializa esas columnas como NA en todas las filas.
###   3. Para cada trimestre ≥ 2023-T4, descarga el microdato con esas vars
###      y matchea por (CODUSU, NRO_HOGAR, COMPONENTE, ANO4, TRIMESTRE),
###      reemplazando los NA con los valores reales.
###   4. Escribe el parquet con 15 columnas.
### -----------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(eph)
  library(glue)
  library(purrr)
})

options(timeout = 600)

vars_clave_match <- c("CODUSU", "NRO_HOGAR", "COMPONENTE", "ANO4", "TRIMESTRE")
vars_nuevas <- c("PP05I", "PP05K")

cat("Cargando parquet actual...\n")
df_base <- arrow::read_parquet("data_raw/df_eph.parquet")
cat("  ", nrow(df_base), "filas,", ncol(df_base), "cols\n\n")

### Inicializar columnas nuevas como NA
df_base$PP05I <- NA_integer_
df_base$PP05K <- NA_integer_

### Trimestres a actualizar (donde EPH tiene PP05I/K disponibles).
periodos_target <- df_base |>
  distinct(ANO4, TRIMESTRE) |>
  filter(ANO4 > 2023 | (ANO4 == 2023 & TRIMESTRE >= 4)) |>
  arrange(ANO4, TRIMESTRE)

cat("Trimestres con PP05I/K a descargar:", nrow(periodos_target), "\n\n")

descargar_pp05 <- function(anio, trim) {
  cat(glue("  {anio}-T{trim}... "))
  tryCatch({
    df <- eph::get_microdata(year = anio, period = trim,
                             vars = c(vars_clave_match, vars_nuevas),
                             type = "individual")
    if (!is.data.frame(df) || nrow(df) == 0) {
      cat("VACÍO\n")
      return(NULL)
    }
    cat(nrow(df), "filas\n")
    df |> select(all_of(c(vars_clave_match, vars_nuevas)))
  }, error = function(e) {
    cat("ERROR:", conditionMessage(e), "\n")
    NULL
  })
}

descargas <- periodos_target |>
  pmap_dfr(function(ANO4, TRIMESTRE) descargar_pp05(ANO4, TRIMESTRE))

cat("\nDescargas totales:", nrow(descargas), "filas\n")

if (nrow(descargas) == 0) {
  stop("No se pudo descargar ningún trimestre. Abortar.")
}

### Reemplazar PP05I/K en df_base usando rows_update.
### rows_update matchea por las vars_clave_match y reemplaza las cols
### que estén en `descargas`, dejando el resto del dataframe intacto.
cat("Mergeando con parquet base...\n")
df_final <- df_base |>
  rows_update(descargas, by = vars_clave_match, unmatched = "ignore")

cat("Filas finales:", nrow(df_final), "\n")
cat("Cols finales:", ncol(df_final), "\n")

### Sanity check: contar no-NAs en PP05I (deben coincidir con descargas).
n_no_na <- sum(!is.na(df_final$PP05I))
cat("Filas con PP05I no-NA:", n_no_na,
    "(esperado:", nrow(descargas), ")\n")

### Escribir
write_parquet(df_final, "data_raw/df_eph.parquet")
cat("\nParquet reescrito.\n")
cat("Tamaño:", round(file.info("data_raw/df_eph.parquet")$size / 1024^2, 2), "MB\n\n")

### Quick stats
cat("Distribución PP05I (cuenta propia/patrones, aportes propios):\n")
print(df_final |> count(PP05I))
cat("\nDistribución PP05K (emisión de facturas):\n")
print(df_final |> count(PP05K))

cat("\nListo.\n")
