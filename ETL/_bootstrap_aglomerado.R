#!/usr/bin/env Rscript
### ONE-OFF (#78): backfill de AGLOMERADO en data_raw/df_eph.parquet.
###
### El microdato local tenía 15 columnas sin AGLOMERADO. En vez de re-descargar
### y REEMPLAZAR todo (riesgo de drift que obligaría a regenerar todos los
### históricos), bajamos sólo AGLOMERADO + claves por trimestre y lo JOINEAMOS
### al microdato existente. Así preservamos los datos exactos y el blast radius
### queda en df_eph.parquet (+1 col) y los panel_runtime (que se regeneran con
### 09 / 09b). Los demás históricos no usan AGLOMERADO y quedan intactos.
###
### Backup previo: data_raw/df_eph.parquet.bak (ya creado).
### Correr una sola vez. Después, 03-update_data.R ya trae AGLOMERADO incremental.

suppressPackageStartupMessages({
  library(dplyr); library(arrow); library(eph); library(purrr); library(glue)
})
options(timeout = 600)

path <- "data_raw/df_eph.parquet"
df <- read_parquet(path)
cat(glue("Microdato actual: {nrow(df)} filas, {ncol(df)} cols\n"))

claves <- c("CODUSU", "NRO_HOGAR", "COMPONENTE", "ANO4", "TRIMESTRE")
periodos <- df |> distinct(ANO4, TRIMESTRE) |> arrange(ANO4, TRIMESTRE)
cat(glue("Períodos a bajar: {nrow(periodos)}\n\n"))

bajar_aglo <- function(anio, trim) {
  tryCatch({
    d <- eph::get_microdata(year = anio, period = trim,
                            vars = c(claves, "AGLOMERADO"), type = "individual")
    if (!is.data.frame(d) || nrow(d) == 0) return(NULL)
    d |> select(all_of(c(claves, "AGLOMERADO")))
  }, error = function(e) {
    message(glue("  FALLO {anio}-T{trim}: {conditionMessage(e)}")); NULL
  })
}

fallos <- character(0)
lookups <- vector("list", nrow(periodos))
for (i in seq_len(nrow(periodos))) {
  a <- periodos$ANO4[i]; t <- periodos$TRIMESTRE[i]
  r <- bajar_aglo(a, t)
  if (is.null(r)) {
    fallos <- c(fallos, glue("{a}-T{t}"))
  } else {
    lookups[[i]] <- r
    cat(glue("  [{i}/{nrow(periodos)}] {a}-T{t}: {nrow(r)} filas\n"))
  }
}

lookup <- list_rbind(lookups) |>
  ### Una persona-trimestre = un AGLOMERADO. distinct por las dudas.
  distinct(across(all_of(claves)), .keep_all = TRUE)
cat(glue("\nLookup AGLOMERADO: {nrow(lookup)} filas\n"))

### Tipos de las claves deben coincidir para el join. eph las devuelve igual,
### pero forzamos por seguridad (CODUSU char; el resto numérico como en df).
for (k in claves) {
  if (is.character(df[[k]])) lookup[[k]] <- as.character(lookup[[k]])
  else lookup[[k]] <- as.numeric(lookup[[k]])
}

### Si AGLOMERADO ya existía (re-run), lo sacamos antes de joinear.
df$AGLOMERADO <- NULL
df2 <- df |> left_join(lookup, by = claves)

n_na <- sum(is.na(df2$AGLOMERADO))
cat(glue("Filas con AGLOMERADO NA (sin match): {n_na} ",
         "({round(100*n_na/nrow(df2), 2)}%)\n"))
cat(glue("Aglomerados distintos: {n_distinct(df2$AGLOMERADO, na.rm = TRUE)}\n"))
if (length(fallos) > 0) cat(glue("Trimestres que fallaron: {paste(fallos, collapse=', ')}\n"))

stopifnot(nrow(df2) == nrow(df))  # el join no debe cambiar el nº de filas
write_parquet(df2, path)
cat(glue("\n✔ Escrito {path}: {nrow(df2)} filas, {ncol(df2)} cols\n"))
cat("BOOTSTRAP_AGLOMERADO_OK\n")
