#!/usr/bin/env Rscript

### -----------------------------------------------------------------------
### 04-rebuild_parquet.R
###
### Script ad-hoc one-shot para re-descargar el parquet completo cuando
### cambia la lista de variables (vars_eph). Esto se necesita porque la
### actualización mensual (03-update_data.R) solo trae trimestres NUEVOS;
### si agregamos columnas, los trimestres viejos del parquet local no
### las van a tener.
###
### Pensado para correr local con buena conexión. Toma ~10-15 min.
###
### Output: data_raw/df_eph.parquet reemplazado con todas las variables.
### -----------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(eph)
  library(glue)
  library(purrr)
})

options(timeout = 600)

### NO source("ETL/01-extract.R") porque ya hace select(all_of(vars_eph))
### con la lista NUEVA, y el parquet actual no tiene las vars nuevas.

vars_eph <- c("CODUSU", "NRO_HOGAR", "COMPONENTE", "ANO4", "TRIMESTRE",
              "CH04", "CH06", "ESTADO", "PONDERA",
              "CAT_OCUP", "PP07H", "PP07J", "PP07K")

cat("Re-bootstrap del parquet con vars:\n  ", paste(vars_eph, collapse = ", "), "\n\n")

### Periodos a descargar = todos los que tenía el parquet actual.
### Lectura sin select para no romper si faltan columnas.
periodos_a_descargar <- arrow::read_parquet(
  "data_raw/df_eph.parquet",
  col_select = c(ANO4, TRIMESTRE)
) |>
  distinct(ANO4, TRIMESTRE) |>
  arrange(ANO4, TRIMESTRE)

n_actual <- arrow::read_parquet(
  "data_raw/df_eph.parquet",
  col_select = c(ANO4)
) |> nrow()

n_total <- nrow(periodos_a_descargar)
cat("Períodos a descargar:", n_total, "\n\n")

descargar_trimestre <- function(anio, trim, idx, total) {
  cat(glue("  [{idx}/{total}] {anio}-T{trim}... "))
  tryCatch({
    df <- eph::get_microdata(year = anio, period = trim,
                             vars = vars_eph, type = "individual")
    if (!is.data.frame(df) || nrow(df) == 0) {
      cat("VACÍO\n")
      return(NULL)
    }
    df_sel <- df |> select(any_of(vars_eph))

    ### Si faltan columnas en este trimestre (ej: PP07J no existía),
    ### las llenamos con NA para que bind_rows funcione.
    faltantes <- setdiff(vars_eph, names(df_sel))
    if (length(faltantes) > 0) {
      for (col in faltantes) {
        df_sel[[col]] <- NA_integer_
      }
      df_sel <- df_sel |> select(all_of(vars_eph))
      cat("ok (faltan: ", paste(faltantes, collapse = ", "), ")\n", sep = "")
    } else {
      cat("ok\n")
    }

    df_sel
  }, error = function(e) {
    cat("ERROR: ", conditionMessage(e), "\n")
    NULL
  })
}

descargas <- periodos_a_descargar |>
  mutate(idx = row_number()) |>
  mutate(datos = pmap(list(ANO4, TRIMESTRE, idx),
                      function(a, t, i) descargar_trimestre(a, t, i, n_total))) |>
  filter(!map_lgl(datos, is.null))

cat("\nDescargados:", nrow(descargas), "/", n_total, "\n")

### Concatenar todos los trimestres en un único dataframe.
df_nuevo <- descargas |>
  pull(datos) |>
  list_rbind()

cat("Filas totales:", nrow(df_nuevo), "\n")
cat("Columnas:", ncol(df_nuevo), "(esperadas:", length(vars_eph), ")\n")

### Verificación de integridad: filas no debe diferir mucho del parquet actual.
delta_pct <- abs(nrow(df_nuevo) - n_actual) / n_actual * 100
cat(glue("Cambio en filas: {n_actual} -> {nrow(df_nuevo)} ({round(delta_pct, 2)}%)\n"))

if (delta_pct > 5) {
  stop("Diferencia de filas > 5% respecto al parquet actual. Abortar y revisar.")
}

### Reemplazar el parquet
write_parquet(df_nuevo, "data_raw/df_eph.parquet")

cat("\nParquet reescrito en data_raw/df_eph.parquet\n")
cat("Tamaño:", round(file.info("data_raw/df_eph.parquet")$size / 1024^2, 2), "MB\n")

### Quick sanity check de las nuevas variables
cat("\nDistribución CAT_OCUP:\n")
print(df_nuevo |> count(CAT_OCUP))
cat("\nDistribución PP07H:\n")
print(df_nuevo |> count(PP07H))

cat("\nListo.\n")
