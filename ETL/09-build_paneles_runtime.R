### Pre-cómputo de paneles para runtime (issue OOM en shinyapps.io).
###
### Genera un único parquet `data_output/panel_runtime.parquet` con todos
### los dúos trimestrales armados (output de armo_base_panel), de modo
### que en producción la app NO necesita cargar el microdato completo
### (~570 MB en RAM) y solo filtra por (anio_0, trim_0) sobre el parquet
### pre-computado (~30-50 MB en Arrow Table lazy).
###
### El parquet contiene el superset de variables que usa cualquiera de
### los 3 análisis (cond_act, cat_ocup, formalidad), evitando duplicar
### un parquet por análisis. Cada fila representa una persona en un dúo
### trimestral con sus valores en t0 y t1.
###
### Cuándo correr este script:
###   - Después de actualizar el microdato (ETL/03-update_data.R agrega
###     nuevos trimestres al df_eph.parquet).
###   - Como paso previo al deploy en GitHub Actions (TODO: integrar
###     en el workflow update_eph_data.yml).
###   - Manualmente cuando se cambie la lógica de armo_base_panel.

suppressPackageStartupMessages({
  source("ETL/00-libraries.R")
  source("ETL/99-functions.R")
  source("ETL/01-extract.R")  ### carga df_eph_full como Arrow Table
})

cat("=== Pre-computando paneles runtime para shinyapps.io ===\n")

### Variables del microdato a propagar al panel armado. Superset de lo
### que cualquiera de los 3 análisis necesita: ESTADO + CAT_OCUP +
### formalidad/formalidad_ampliada + PONDERA. Los IDs (CODUSU, NRO_HOGAR,
### COMPONENTE) los agrega organize_panels() automáticamente.
variables_runtime <- c("ESTADO", "CAT_OCUP", "PP07H", "PP05I", "PP05K",
                       "formalidad", "formalidad_ampliada", "PONDERA")

### Enumerar todos los dúos válidos (existen ambos trimestres en el
### microdato). Esquema 2-2-2: trimestres consecutivos T1-T2, T2-T3,
### T3-T4 dentro del mismo año, y T4-T1 entre años contiguos.
duos_validos <- periodos_disponibles |>
  dplyr::mutate(
    anio_post = dplyr::if_else(TRIMESTRE %in% 1:3, ANO4, ANO4 + 1L),
    trim_post = dplyr::if_else(TRIMESTRE %in% 1:3, TRIMESTRE + 1L, 1L)
  ) |>
  dplyr::mutate(
    tiene_post = paste(anio_post, trim_post) %in%
      paste(periodos_disponibles$ANO4, periodos_disponibles$TRIMESTRE)
  ) |>
  dplyr::filter(tiene_post) |>
  dplyr::select(-tiene_post)

cat(glue::glue("Dúos a pre-computar: {nrow(duos_validos)}\n\n"))

### Iterar dúos y armar cada panel con armo_base_panel(). Anotar el dúo
### como cols (anio_0, trim_0) para poder filtrar en runtime.
paneles_lista <- purrr::pmap(
  duos_validos,
  function(ANO4, TRIMESTRE, anio_post, trim_post) {
    cat(glue::glue("  · {ANO4}-T{TRIMESTRE} → {anio_post}-T{trim_post}\n"))
    armo_base_panel(
      anio_0 = ANO4, trimestre_0 = TRIMESTRE,
      anio_1 = anio_post, trimestre_1 = trim_post,
      df = df_eph_full,
      variables = variables_runtime
    ) |>
      dplyr::mutate(anio_0 = ANO4, trim_0 = TRIMESTRE,
                    .before = 1)
  }
)

panel_runtime <- purrr::list_rbind(paneles_lista)

cat(glue::glue("\nPanel runtime construido: {nrow(panel_runtime)} filas, ",
               "{ncol(panel_runtime)} columnas\n"))

### Forzar tipos consistentes (los character cols deben ser char puros,
### los numeric integer cuando aplica) antes de escribir el parquet.
### El Periodo viene como yearq (zoo) y arrow no lo soporta nativo;
### lo paso a character para evitar errores de schema en arrow::write_parquet.
panel_runtime <- panel_runtime |>
  dplyr::mutate(
    Periodo = as.character(Periodo)
  )

path_out <- "data_output/panel_runtime.parquet"
arrow::write_parquet(panel_runtime, path_out, compression = "snappy")

tamanio_mb <- round(file.size(path_out) / 1024 / 1024, 2)
cat(glue::glue("\n✔ Escrito: {path_out} ({tamanio_mb} MB en disco)\n"))
cat(glue::glue("  Dúos contenidos: {dplyr::n_distinct(panel_runtime[, c('anio_0', 'trim_0')])}\n\n"))

### CSV gzip espejo del parquet para descarga universal (issue #35).
### Pesa ~23 MB con compresión, vs ~199 MB sin comprimir. readr::write_csv
### detecta la extensión .gz y comprime automáticamente.
path_out_csv <- "data_output/panel_runtime.csv.gz"
readr::write_csv(panel_runtime, path_out_csv)
cat(glue::glue("✔ Escrito: {path_out_csv} ({round(file.size(path_out_csv)/1024/1024, 2)} MB en disco)\n\n"))

### Sanity check: leer y filtrar uno de los dúos más recientes para
### verificar que el resultado coincide con armo_base_panel() directo.
duo_test <- duos_validos |> dplyr::slice_tail(n = 1)
cat(glue::glue("Sanity check: dúo {duo_test$ANO4}-T{duo_test$TRIMESTRE} → ",
               "{duo_test$anio_post}-T{duo_test$trim_post}\n"))

panel_pre <- arrow::read_parquet(path_out, as_data_frame = FALSE) |>
  dplyr::filter(anio_0 == duo_test$ANO4, trim_0 == duo_test$TRIMESTRE) |>
  dplyr::collect()

panel_directo <- armo_base_panel(
  anio_0 = duo_test$ANO4, trimestre_0 = duo_test$TRIMESTRE,
  anio_1 = duo_test$anio_post, trimestre_1 = duo_test$trim_post,
  df = df_eph_full,
  variables = variables_runtime
)

cat(glue::glue("  filas pre-computadas: {nrow(panel_pre)}\n"))
cat(glue::glue("  filas directo:       {nrow(panel_directo)}\n"))
if (nrow(panel_pre) == nrow(panel_directo)) {
  cat("  ✔ OK\n\n")
} else {
  warning("Discrepancia entre panel pre-computado y directo. Revisar.")
}
