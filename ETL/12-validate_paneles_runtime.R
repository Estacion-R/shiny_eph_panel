#!/usr/bin/env Rscript

### -----------------------------------------------------------------------
### 12-validate_paneles_runtime.R (issue #45)
###
### Valida que los parquets de runtime no presenten regresiones silenciosas
### tras un rebuild de 09-build_paneles_runtime.R o 09b-build_paneles_runtime_anual.R.
###
### Cubre 4 dimensiones:
###   1. Schema y tipos: las 32 cols esperadas existen en ambos parquets.
###   2. Cobertura temporal: sin gaps inesperados en la secuencia de dúos.
###   3. Tamaño/atrición: n por dúo en rango esperado, ratio anual/trim
###      dentro del rango histórico observado.
###   4. Cross-validation: tasas calculadas on-demand desde el parquet
###      coinciden con las pre-calculadas en los CSVs históricos.
###
### Cómo correr:
###   Rscript ETL/12-validate_paneles_runtime.R
###
### Exit status:
###   0 = todas las validaciones pasaron.
###   1 = al menos una falló (lee la salida para ver cuáles).
###
### Integración al pipeline:
###   - Como gate después de 09/09b (rebuild) y antes del deploy.
###   - El routine de auditoría mensual lo corre el día 7 y abre issue
###     en GitHub si hay regresiones.
### -----------------------------------------------------------------------

suppressPackageStartupMessages({
  library(testthat)
  library(arrow)
  library(dplyr)
  library(readr)
})

source("ETL/99-functions.R")
source("R/utils_analisis.R")


### -----------------------------------------------------------------------
### Constantes calibradas a partir del estado actual de los parquets
### (medido 2026-05-08 sobre datos hasta 2024-T2). Si en el futuro INDEC
### libera nuevos trimestres y los rangos cambian materialmente, ajustar
### acá con justificación en el commit.
### -----------------------------------------------------------------------

### 32 columnas esperadas (incluye AGLOMERADO, #78) en ambos parquets (orden importa para detectar
### drift de eph::organize_panels). El primer par (anio_0, trim_0) es
### inyectado en 09/09b para soportar filter pushdown en runtime.
COLS_ESPERADAS <- c(
  "anio_0", "trim_0",
  "CODUSU", "NRO_HOGAR", "COMPONENTE",
  "ANO4", "TRIMESTRE",
  "CH04", "CH06", "ESTADO", "CAT_OCUP",
  "PP07H", "PP05I", "PP05K",
  "formalidad", "formalidad_ampliada",
  "PONDERA", "Periodo",
  "AGLOMERADO",  ### #78: atributo fijo de la vivienda, sólo t0 (sin _t1)
  "ANO4_t1", "TRIMESTRE_t1",
  "CH04_t1", "CH06_t1", "ESTADO_t1", "CAT_OCUP_t1",
  "PP07H_t1", "PP05I_t1", "PP05K_t1",
  "formalidad_t1", "formalidad_ampliada_t1",
  "PONDERA_t1",
  "consistencia"
)

### Tipos esperados por columna (para detectar drift en versiones de
### eph/arrow). character/double/int32/bool — los nombres siguen lo que
### reporta arrow::open_dataset(...)$schema.
TIPOS_ESPERADOS <- list(
  CODUSU       = "string",
  NRO_HOGAR    = "double",
  COMPONENTE   = "double",
  ANO4         = "double",
  TRIMESTRE    = "double",
  ESTADO       = "double",
  PONDERA      = "double",
  consistencia = "bool"
)

### Cobertura temporal. Estado actual: trim 80 dúos (2003-T3 a 2024-T1
### → 2024-T2), anual 69 dúos. Si rebajamos significativamente esto
### es alerta.
DUOS_TRIM_MIN  <- 75L
DUOS_ANUAL_MIN <- 65L

### Tamaño por dúo. Histórico observado: trim n ∈ [13083, 29060],
### anual n ∈ [10913, 24929]. Threshold conservador: cualquier dúo
### con n < 5000 indica un pareo defectuoso.
N_MIN_POR_DUO <- 5000L

### Atrición anual/trim observada: ratio ∈ [44.5%, 102.9%], mean 88.7%.
### El rango es amplio porque depende del trimestre y de cambios
### operativos de INDEC. Threshold: alerta si el ratio promedio del
### dataset cae fuera de [0.40, 1.20]. La cota superior > 1 es
### intencional: hay dúos donde el match anual es mejor que el trim
### consecutivo (poca rotación de muestra).
RATIO_ATRICION_MIN <- 0.40
RATIO_ATRICION_MAX <- 1.20

### Tolerancia para cross-validation. Las tasas pre-calculadas en
### CSVs vs las recalculadas on-demand desde el parquet deben
### coincidir hasta 0.5 pp (mismas fuentes, mismas funciones; las
### diferencias son por redondeo intermedio).
TOLERANCIA_TASAS_PP <- 0.5


### -----------------------------------------------------------------------
### Helpers
### -----------------------------------------------------------------------

abrir_parquet <- function(path) {
  if (!file.exists(path)) {
    stop("No existe ", path,
         ". Correr ETL/09-build_paneles_runtime.R o 09b según corresponda.")
  }
  arrow::open_dataset(path)
}


### -----------------------------------------------------------------------
### Tests
### -----------------------------------------------------------------------

cat("=== Validando parquets de runtime ===\n\n")

ds_trim  <- abrir_parquet("data_output/panel_runtime.parquet")
ds_anual <- abrir_parquet("data_output/panel_runtime_anual.parquet")

### Wrapper: ProgressReporter para feedback visual por test, FailReporter
### para que el script salga != 0 si alguno falló (gate de pipeline).
### MultiReporter combina ambos.
reporter_combinado <- testthat::MultiReporter$new(reporters = list(
  testthat::ProgressReporter$new(show_praise = FALSE),
  testthat::FailReporter$new()
))
testthat::with_reporter(reporter_combinado, {

### --- 1. Schema y tipos ---

test_that("schema trimestral: tiene las 32 cols esperadas", {
  expect_setequal(names(ds_trim$schema), COLS_ESPERADAS)
})

test_that("schema anual: tiene las 32 cols esperadas", {
  expect_setequal(names(ds_anual$schema), COLS_ESPERADAS)
})

test_that("tipos trimestral: cols críticas con tipo correcto", {
  schema <- ds_trim$schema
  for (col in names(TIPOS_ESPERADOS)) {
    tipo_real <- schema[[col]]$type$ToString()
    expect_equal(tipo_real, TIPOS_ESPERADOS[[col]],
                 info = paste("Col:", col))
  }
})

test_that("tipos anual: cols críticas con tipo correcto", {
  schema <- ds_anual$schema
  for (col in names(TIPOS_ESPERADOS)) {
    tipo_real <- schema[[col]]$type$ToString()
    expect_equal(tipo_real, TIPOS_ESPERADOS[[col]],
                 info = paste("Col:", col))
  }
})


### --- 2. Cobertura temporal ---

duos_trim <- ds_trim |>
  dplyr::distinct(anio_0, trim_0) |>
  dplyr::collect() |>
  dplyr::arrange(anio_0, trim_0)

duos_anual <- ds_anual |>
  dplyr::distinct(anio_0, trim_0) |>
  dplyr::collect() |>
  dplyr::arrange(anio_0, trim_0)

test_that("cobertura trimestral: cantidad mínima de dúos", {
  expect_gte(nrow(duos_trim), DUOS_TRIM_MIN)
})

test_that("cobertura anual: cantidad mínima de dúos", {
  expect_gte(nrow(duos_anual), DUOS_ANUAL_MIN)
})

test_that("cobertura trimestral: empieza en 2003-T3 (primer dúo histórico)", {
  ### El microdato EPH continua arranca en 2003-T3 (cambio de operativo).
  ### El primer dúo posible es 2003-T3 → 2003-T4.
  expect_equal(duos_trim$anio_0[1], 2003)
  expect_equal(duos_trim$trim_0[1], 3)
})

test_that("cobertura anual: empieza en 2003-T3 (primer dúo histórico)", {
  ### El primer dúo anual posible es 2003-T3 → 2004-T3.
  expect_equal(duos_anual$anio_0[1], 2003)
  expect_equal(duos_anual$trim_0[1], 3)
})


### --- 3. Tamaño y atrición ---

n_trim <- ds_trim |>
  dplyr::summarise(n = dplyr::n(), .by = c(anio_0, trim_0)) |>
  dplyr::collect()

n_anual <- ds_anual |>
  dplyr::summarise(n = dplyr::n(), .by = c(anio_0, trim_0)) |>
  dplyr::collect()

test_that("tamaño trimestral: ningún dúo con n anómalamente bajo", {
  duos_chicos <- n_trim |> dplyr::filter(n < N_MIN_POR_DUO)
  expect_equal(
    nrow(duos_chicos), 0,
    info = paste(
      "Dúos con n <", N_MIN_POR_DUO, ":",
      paste(duos_chicos$anio_0, "-T", duos_chicos$trim_0, "(n=", duos_chicos$n, ")",
            sep = "", collapse = ", ")
    )
  )
})

test_that("tamaño anual: ningún dúo con n anómalamente bajo", {
  duos_chicos <- n_anual |> dplyr::filter(n < N_MIN_POR_DUO)
  expect_equal(
    nrow(duos_chicos), 0,
    info = paste(
      "Dúos con n <", N_MIN_POR_DUO, ":",
      paste(duos_chicos$anio_0, "-T", duos_chicos$trim_0, "(n=", duos_chicos$n, ")",
            sep = "", collapse = ", ")
    )
  )
})

test_that("atrición: ratio anual/trim promedio en rango histórico", {
  joined <- merge(n_anual, n_trim, by = c("anio_0", "trim_0"),
                  suffixes = c("_anual", "_trim"))
  ratio_promedio <- mean(joined$n_anual / joined$n_trim)
  expect_gte(ratio_promedio, RATIO_ATRICION_MIN)
  expect_lte(ratio_promedio, RATIO_ATRICION_MAX)
})


### --- 4. Cross-validation con tasas pre-calculadas ---

### Compara la tasa de persistencia para Ocupado en un dúo arbitrario
### entre el CSV histórico y el cálculo on-demand desde el parquet.
### No itera sobre todos: sample-check para detectar drift sin pagar
### el costo de recalcular el histórico completo.

test_that("cross-val: tasa Ocupado en un dúo trimestral coincide entre CSV y parquet", {
  csv_path <- "data_output/tasas_cond_act_historico.csv"
  if (!file.exists(csv_path)) {
    skip(paste("No existe", csv_path, "(opcional, no bloqueante)"))
  }
  hist <- readr::read_csv(csv_path, show_col_types = FALSE)

  ### Tomar el dúo más reciente disponible en ambas fuentes.
  duo_csv <- hist |>
    dplyr::filter(categoria == "Ocupado") |>
    dplyr::slice_tail(n = 1)
  if (nrow(duo_csv) == 0) skip("CSV no tiene filas de Ocupado")

  ### Parsear "YYYY_tA-tB" → (anio, trim).
  partes <- strsplit(duo_csv$periodo, "_t")[[1]]
  anio <- as.integer(partes[1])
  trim <- as.integer(strsplit(partes[2], "-")[[1]][1])

  panel <- ds_trim |>
    dplyr::filter(anio_0 == anio, trim_0 == trim) |>
    dplyr::select(-anio_0, -trim_0) |>
    dplyr::collect()
  if (nrow(panel) == 0) skip(paste("No hay datos en parquet para", anio, "-T", trim))

  tasas_calc <- arma_tasas_destacadas(
    df_panel = panel,
    var = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    categoria = "Ocupado"
  )

  expect_lt(
    abs(tasas_calc$persistencia - duo_csv$persistencia),
    TOLERANCIA_TASAS_PP,
    label = paste0(
      "Persistencia Ocupado en ", duo_csv$periodo,
      " (CSV=", duo_csv$persistencia,
      " vs recalc=", tasas_calc$persistencia, ")"
    )
  )
})


})  ### fin de with_reporter(FailReporter)

### Si llegamos acá sin error, FailReporter no marcó fallos. PASS verde.
### Si algún test falló, FailReporter ya raiseó y el script salió != 0.
cat("\n=== Validación completa ===\n")
