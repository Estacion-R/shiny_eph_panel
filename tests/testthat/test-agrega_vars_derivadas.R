### Tests de agrega_vars_derivadas() (en ETL/99-functions.R).
###
### Esta función agrega las columnas derivadas `formalidad` (clásica
### EPH, solo asalariados) y `formalidad_ampliada` (OIT 2023, todos
### los ocupados con info de aportes) al microdato.
###
### Los casos a cubrir vienen del case_when() de la función:
###
### formalidad:
###   CAT_OCUP=3 & PP07H=1 → 1L (Formal)
###   CAT_OCUP=3 & PP07H=2 → 2L (Informal)
###   resto                → NA
###
### formalidad_ampliada:
###   CAT_OCUP=3 & PP07H=1                              → 1L
###   CAT_OCUP=3 & PP07H=2                              → 2L
###   CAT_OCUP in (1,2) & (PP05I=1 | PP05K=1)           → 1L
###   CAT_OCUP in (1,2) & PP05I=2 & PP05K=2             → 2L
###   CAT_OCUP=4                                        → 2L (TFSR siempre informal)
###   resto                                             → NA

test_that("agrega_vars_derivadas suma las dos columnas al schema", {
  df <- load_panel_mock()
  out <- agrega_vars_derivadas(df)

  expect_true(all(c("formalidad", "formalidad_ampliada") %in% names(out)))
  expect_equal(nrow(out), nrow(df))
})


test_that("formalidad clásica: asalariados con PP07H=1 son Formales (1L)", {
  ### Construir caso controlado en lugar de depender del fixture random.
  df <- tibble::tibble(
    CAT_OCUP = c(3L, 3L, 1L, 2L, 4L),
    PP07H    = c(1L, 2L, 1L, 1L, 1L),
    PP05I    = c(NA_integer_, NA_integer_, 1L, 2L, NA_integer_),
    PP05K    = c(NA_integer_, NA_integer_, 2L, 1L, NA_integer_)
  )
  out <- agrega_vars_derivadas(df)

  expect_equal(out$formalidad, c(1L, 2L, NA_integer_, NA_integer_, NA_integer_))
})


test_that("formalidad_ampliada cubre cuenta propia y patrones", {
  df <- tibble::tibble(
    CAT_OCUP = c(3L, 3L, 1L, 1L, 2L, 2L, 4L, 4L),
    PP07H    = c(1L, 2L, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_),
    PP05I    = c(NA_integer_, NA_integer_, 1L, 2L, 2L, 1L, NA_integer_, NA_integer_),
    PP05K    = c(NA_integer_, NA_integer_, 2L, 2L, 1L, 2L, NA_integer_, NA_integer_)
  )
  out <- agrega_vars_derivadas(df)

  ### Asalariado con PP07H=1: Formal (1L)
  expect_equal(out$formalidad_ampliada[1], 1L)
  ### Asalariado con PP07H=2: Informal (2L)
  expect_equal(out$formalidad_ampliada[2], 2L)
  ### Patrón con PP05I=1: Formal (paga monotributo)
  expect_equal(out$formalidad_ampliada[3], 1L)
  ### Patrón sin aportes ni monotributo: Informal
  expect_equal(out$formalidad_ampliada[4], 2L)
  ### Cuenta propia con PP05K=1: Formal (hace aportes propios)
  expect_equal(out$formalidad_ampliada[5], 1L)
  ### Cuenta propia con PP05I=1: Formal
  expect_equal(out$formalidad_ampliada[6], 1L)
  ### TFSR siempre Informal (regla CAT_OCUP=4 → 2L)
  expect_equal(out$formalidad_ampliada[7], 2L)
  expect_equal(out$formalidad_ampliada[8], 2L)
})


test_that("agrega_vars_derivadas es defensivo: no rompe sin las cols requeridas", {
  ### Si falta CAT_OCUP, PP07H, PP05I o PP05K, la función debe completarlas
  ### con NA y NO tirar error.
  df_minimo <- tibble::tibble(ANO4 = 2024L, TRIMESTRE = 1L)
  out <- agrega_vars_derivadas(df_minimo)

  expect_true(all(c("formalidad", "formalidad_ampliada") %in% names(out)))
  expect_true(is.na(out$formalidad))
  expect_true(is.na(out$formalidad_ampliada))
})


test_that("agrega_vars_derivadas preserva las columnas originales", {
  df <- load_panel_mock()
  cols_originales <- names(df)
  out <- agrega_vars_derivadas(df)

  expect_true(all(cols_originales %in% names(out)))
})


test_that("agrega_vars_derivadas: invariantes de rango (1L o 2L o NA)", {
  df <- load_panel_mock()
  out <- agrega_vars_derivadas(df)

  expect_true(all(out$formalidad %in% c(1L, 2L, NA_integer_)))
  expect_true(all(out$formalidad_ampliada %in% c(1L, 2L, NA_integer_)))
})
