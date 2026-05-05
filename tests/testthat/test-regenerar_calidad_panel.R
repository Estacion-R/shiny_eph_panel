### Tests de regenerar_calidad_panel() (en ETL/99-functions.R).
###
### Función que regenera incrementalmente un CSV de métricas de calidad
### de panel (% encontrado, % inconsistencias por sexo/edad). Acepta
### `window` (issue #47): "trimestral" (default) o "anual".
###
### Estrategia: fixture sintético + with_tempdir() para que el CSV se
### escriba a un dir temporal sin tocar data_output/.

test_that("regenerar_calidad_panel trimestral genera CSV con schema esperado", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_calidad.csv")

    out <- regenerar_calidad_panel(
      path_csv     = path,
      df_microdato = df_microdato,
      window       = "trimestral"
    )

    expect_true(file.exists(path))

    df <- readr::read_csv(path, show_col_types = FALSE)

    cols_esperadas <- c(
      "periodo", "anio_0", "trim_0", "anio_1", "trim_1",
      "n_t0", "pondera_t0", "n_panel", "pondera_panel",
      "n_inc_total", "n_inc_sexo", "n_inc_edad",
      "pondera_inc_total", "pondera_inc_sexo", "pondera_inc_edad",
      "pct_encontrado_n", "pct_encontrado_pondera",
      "pct_inc_total", "pct_inc_sexo", "pct_inc_edad"
    )
    expect_true(all(cols_esperadas %in% names(df)))
    expect_gt(nrow(df), 0)
  })
})


test_that("trimestral: periodos en formato 'YYYY_tA-tB'", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_calidad.csv")

    regenerar_calidad_panel(
      path_csv     = path,
      df_microdato = df_microdato,
      window       = "trimestral"
    )

    df <- readr::read_csv(path, show_col_types = FALSE)
    expect_true(all(df$periodo %in% c("2024_t1-t2", "2024_t2-t3")))
  })
})


test_that("anual: periodos en formato 'YYYY_tN' (sin '-tM')", {
  ### Microdato extendido a 2025 para tener un dúo anual válido.
  base <- load_panel_mock()
  df_2025 <- base |>
    dplyr::filter(TRIMESTRE == 1L) |>
    dplyr::mutate(
      ANO4 = 2025L,
      CH06 = CH06 + 1L  # avanza 1 año (consistente con esperado para anual)
    )
  df_microdato <- dplyr::bind_rows(base, df_2025) |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_calidad_anual.csv")

    regenerar_calidad_panel(
      path_csv     = path,
      df_microdato = df_microdato,
      window       = "anual"
    )

    df <- readr::read_csv(path, show_col_types = FALSE)
    expect_true(all(df$periodo == "2024_t1"))
  })
})


test_that("idempotencia: segunda corrida no agrega filas duplicadas", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_calidad.csv")

    regenerar_calidad_panel(
      path_csv     = path,
      df_microdato = df_microdato,
      window       = "trimestral"
    )
    n_primera <- nrow(readr::read_csv(path, show_col_types = FALSE))

    regenerar_calidad_panel(
      path_csv     = path,
      df_microdato = df_microdato,
      window       = "trimestral"
    )
    n_segunda <- nrow(readr::read_csv(path, show_col_types = FALSE))

    expect_equal(n_segunda, n_primera)
  })
})


test_that("invariante: porcentajes en rango [0, 100]", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_calidad.csv")

    regenerar_calidad_panel(
      path_csv     = path,
      df_microdato = df_microdato,
      window       = "trimestral"
    )

    df <- readr::read_csv(path, show_col_types = FALSE)
    expect_true(all(df$pct_encontrado_n >= 0 & df$pct_encontrado_n <= 100))
    expect_true(all(df$pct_encontrado_pondera >= 0 & df$pct_encontrado_pondera <= 100))
    expect_true(all(df$pct_inc_total >= 0 & df$pct_inc_total <= 100))
    expect_true(all(df$pct_inc_sexo >= 0 & df$pct_inc_sexo <= 100))
    expect_true(all(df$pct_inc_edad >= 0 & df$pct_inc_edad <= 100))
  })
})


test_that("invariante: n_panel <= n_t0 (encontrados nunca > totales)", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_calidad.csv")

    regenerar_calidad_panel(
      path_csv     = path,
      df_microdato = df_microdato,
      window       = "trimestral"
    )

    df <- readr::read_csv(path, show_col_types = FALSE)
    expect_true(all(df$n_panel <= df$n_t0))
    expect_true(all(df$pondera_panel <= df$pondera_t0))
  })
})
