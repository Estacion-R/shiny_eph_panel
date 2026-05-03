### Pre-cómputo de paneles INTERANUALES para runtime (issue #44).
###
### Espejo de ETL/09-build_paneles_runtime.R pero con `window = "anual"`:
### parea cada vivienda con el MISMO trimestre del año siguiente
### (T1 año X ↔ T1 año X+1, T2-T2, T3-T3, T4-T4) en lugar de trimestres
### consecutivos. Permite neutralizar la estacionalidad y leer cambios
### estructurales anuales sobre las mismas personas.
###
### Schema idéntico al panel intertrim (panel_runtime.parquet): mismas
### columnas, distinto contenido. Esto facilita que los módulos hagan
### switch en runtime sin cambiar la estructura de datos.
###
### Cuándo correr:
###   - Después de actualizar el microdato (ETL/03-update_data.R).
###   - Junto al 09-build_paneles_runtime.R (deben mantenerse en sincronía).
###   - Manualmente cuando se cambie la lógica de armo_base_panel.

suppressPackageStartupMessages({
  source("ETL/00-libraries.R")
  source("ETL/99-functions.R")
})

cat("=== Pre-computando paneles INTERANUALES (anual) para shinyapps.io ===\n")

### Cargar el microdato + sumar vars derivadas (formalidad / formalidad_ampliada)
### que organize_panels necesita como variables a propagar. 01-extract.R en
### runtime no carga el microdato (solo el panel pre-computado), por eso
### lo levantamos acá tal como hace 03-update_data.R.
df_eph_full <- arrow::read_parquet("data_raw/df_eph.parquet") |>
  agrega_vars_derivadas()

### Enumerar periodos disponibles (ANO4, TRIMESTRE) en el microdato.
periodos_disponibles <- df_eph_full |>
  dplyr::distinct(ANO4, TRIMESTRE) |>
  dplyr::arrange(ANO4, TRIMESTRE)

### Mismo superset de variables que el panel intertrim, para que el
### switch en runtime no requiera distintos schemas.
variables_runtime <- c("ESTADO", "CAT_OCUP", "PP07H", "PP05I", "PP05K",
                       "formalidad", "formalidad_ampliada", "PONDERA")

### Enumerar dúos anuales válidos: cada periodo (ANO4, TRIMESTRE) se
### parea con (ANO4+1, TRIMESTRE) si éste existe en el microdato.
duos_anuales <- periodos_disponibles |>
  dplyr::mutate(
    anio_post = ANO4 + 1L,
    trim_post = TRIMESTRE
  ) |>
  dplyr::mutate(
    tiene_post = paste(anio_post, trim_post) %in%
      paste(periodos_disponibles$ANO4, periodos_disponibles$TRIMESTRE)
  ) |>
  dplyr::filter(tiene_post) |>
  dplyr::select(-tiene_post)

cat(glue::glue("Dúos anuales a pre-computar: {nrow(duos_anuales)}\n\n"))

### Iterar dúos y armar cada panel con organize_panels(window="anual").
### Anotamos el dúo como cols (anio_0, trim_0) para poder filtrar en runtime
### igual que en el panel intertrim.
paneles_lista <- purrr::pmap(
  duos_anuales,
  function(ANO4, TRIMESTRE, anio_post, trim_post) {
    cat(glue::glue("  · {ANO4}-T{TRIMESTRE} → {anio_post}-T{trim_post}\n"))

    list_eph_panel <- list(
      df_eph_full |>
        dplyr::filter(ANO4 == !!ANO4 & TRIMESTRE == !!TRIMESTRE),
      df_eph_full |>
        dplyr::filter(ANO4 == !!anio_post & TRIMESTRE == !!trim_post)
    )

    eph::organize_panels(
      bases = list_eph_panel,
      variables = variables_runtime,
      window = "anual"
    ) |>
      dplyr::mutate(anio_0 = ANO4, trim_0 = TRIMESTRE, .before = 1)
  }
)

panel_runtime_anual <- purrr::list_rbind(paneles_lista)

cat(glue::glue("\nPanel anual construido: {nrow(panel_runtime_anual)} filas, ",
               "{ncol(panel_runtime_anual)} columnas\n"))

### Forzar tipos consistentes antes de write_parquet (Periodo viene como
### yearq y arrow no lo soporta nativo).
panel_runtime_anual <- panel_runtime_anual |>
  dplyr::mutate(Periodo = as.character(Periodo))

path_out <- "data_output/panel_runtime_anual.parquet"
arrow::write_parquet(panel_runtime_anual, path_out, compression = "snappy")

tamanio_mb <- round(file.size(path_out) / 1024 / 1024, 2)
cat(glue::glue("\n✔ Escrito: {path_out} ({tamanio_mb} MB en disco)\n"))
cat(glue::glue("  Dúos contenidos: ",
               "{dplyr::n_distinct(panel_runtime_anual[, c('anio_0', 'trim_0')])}\n\n"))

### CSV gzip espejo del parquet para descarga universal (issue #35,
### sumarlo a la sección Datos en una segunda iteración).
path_out_csv <- "data_output/panel_runtime_anual.csv.gz"
readr::write_csv(panel_runtime_anual, path_out_csv)
cat(glue::glue("✔ Escrito: {path_out_csv} ",
               "({round(file.size(path_out_csv)/1024/1024, 2)} MB en disco)\n\n"))

### Sanity check: el último dúo anual del dataset debe tener una cantidad
### razonable de personas pareadas. Threshold: > 5000 (los dúos anuales más
### chicos típicamente rondan 8-15k según atrición a 4 trimestres).
duo_test <- duos_anuales |> dplyr::slice_tail(n = 1)
panel_test <- panel_runtime_anual |>
  dplyr::filter(anio_0 == duo_test$ANO4, trim_0 == duo_test$TRIMESTRE)
cat(glue::glue("Sanity check: dúo anual {duo_test$ANO4}-T{duo_test$TRIMESTRE} → ",
               "{duo_test$anio_post}-T{duo_test$trim_post}\n"))
cat(glue::glue("  filas pareadas: {nrow(panel_test)}\n"))
if (nrow(panel_test) >= 5000) {
  cat("  ✔ OK (>= 5000)\n\n")
} else {
  warning(glue::glue("Pareo anual chico ({nrow(panel_test)} filas). ",
                     "Revisar atrición y window de organize_panels."))
}
