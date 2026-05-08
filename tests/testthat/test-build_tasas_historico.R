### Tests de build_tasas_historico() (en ETL/99-functions.R).
###
### Construye un tibble con (periodo, categoria, persistencia, salida,
### entrada) iterando sobre todos los duos válidos del microdato. NO
### escribe a disco — devuelve el tibble in-memory.
###
### Acepta `window`: "trimestral" (default) o "anual" (issue #46).

test_that("build_tasas_historico trimestral: schema y filas > 0", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  out <- build_tasas_historico(
    df_microdato = df_microdato,
    var          = "ESTADO",
    etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    window       = "trimestral"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("periodo", "categoria", "persistencia", "salida",
                    "entrada") %in% names(out)))
  expect_gt(nrow(out), 0)
})


test_that("trimestral: periodos en formato 'YYYY_tA-tB'", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  out <- build_tasas_historico(
    df_microdato = df_microdato,
    var          = "ESTADO",
    etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    window       = "trimestral"
  )

  ### Fixture tiene 2024-T1, T2, T3 → 2 dúos consecutivos.
  expect_true(all(out$periodo %in% c("2024_t1-t2", "2024_t2-t3")))
})


test_that("anual: periodos en formato 'YYYY_tN' (sin '-tM')", {
  ### Construir microdato extendido a 2025-T1 para tener al menos un dúo
  ### anual válido (2024-T1 → 2025-T1).
  base <- load_panel_mock()
  df_2025 <- base |>
    dplyr::filter(TRIMESTRE == 1L) |>
    dplyr::mutate(ANO4 = 2025L)
  df_microdato <- dplyr::bind_rows(base, df_2025) |> agrega_vars_derivadas()

  out <- build_tasas_historico(
    df_microdato = df_microdato,
    var          = "ESTADO",
    etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    window       = "anual"
  )

  ### Solo dúo válido: 2024-T1 → 2025-T1, periodo "2024_t1".
  expect_true(all(out$periodo == "2024_t1"))
})


test_that("una fila por (periodo, categoria) y todas las etiquetas presentes", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()
  etiquetas <- c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar")

  out <- build_tasas_historico(
    df_microdato = df_microdato,
    var          = "ESTADO",
    etiquetas    = etiquetas,
    window       = "trimestral"
  )

  ### 2 dúos x 4 categorías = hasta 8 filas. Puede haber menos si alguna
  ### categoría no es computable en algún dúo, pero todas deberían estar
  ### representadas al menos una vez en el panel mock.
  expect_setequal(unique(out$categoria), etiquetas)
})


test_that("invariante: persistencia + salida = 100 por fila", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  out <- build_tasas_historico(
    df_microdato = df_microdato,
    var          = "ESTADO",
    etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    window       = "trimestral"
  )

  ### Tolerancia ±0.2 pp por redondeo a 1 decimal en ambas tasas.
  deltas <- abs(out$persistencia + out$salida - 100)
  expect_true(all(deltas < 0.2))
})


test_that("invariante: tasas en rango [0, 100]", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  out <- build_tasas_historico(
    df_microdato = df_microdato,
    var          = "ESTADO",
    etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    window       = "trimestral"
  )

  expect_true(all(out$persistencia >= 0 & out$persistencia <= 100))
  expect_true(all(out$salida >= 0 & out$salida <= 100))
  expect_true(all(out$entrada >= 0 & out$entrada <= 100))
})


test_that("desde_panel filtra periodos previos", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  ### Sin filtro: 2 dúos (2024_t1-t2, 2024_t2-t3).
  out_full <- build_tasas_historico(
    df_microdato = df_microdato,
    var          = "ESTADO",
    etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    window       = "trimestral"
  )

  ### Con desde_panel = "2024T2": solo 2024_t2-t3.
  out_filt <- build_tasas_historico(
    df_microdato = df_microdato,
    var          = "ESTADO",
    etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    desde_panel  = "2024T2",
    window       = "trimestral"
  )

  expect_true(all(out_filt$periodo == "2024_t2-t3"))
  expect_lt(nrow(out_filt), nrow(out_full))
})


test_that("vars_extra: pasa columnas extra al panel sin afectar el output schema", {
  ### vars_extra se usa internamente en armo_base_panel para incluir cols
  ### adicionales en el panel (ej: CH04, CH06 para validaciones), pero el
  ### output de tasas no las expone.
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  out <- build_tasas_historico(
    df_microdato = df_microdato,
    var          = "ESTADO",
    etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    vars_extra   = c("CH04", "CH06"),
    window       = "trimestral"
  )

  expect_setequal(names(out), c("periodo", "categoria", "persistencia",
                                "salida", "entrada"))
})
