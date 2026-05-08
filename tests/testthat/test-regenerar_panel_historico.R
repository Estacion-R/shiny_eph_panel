### Tests de regenerar_panel_historico() (en ETL/99-functions.R).
###
### Función que regenera incrementalmente un CSV histórico de panel
### para un análisis dado. Acepta `window` (issue #46): "trimestral"
### (default) o "anual".
###
### Estrategia: usar el fixture sintético + with_tempdir() para que el
### CSV se escriba a un dir temporal sin tocar data_output/.

test_that("regenerar_panel_historico trimestral genera CSV con schema esperado", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_panel.csv")

    out <- regenerar_panel_historico(
      path_csv     = path,
      df_microdato = df_microdato,
      var          = "ESTADO",
      etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
      categorias   = c("Ocupado", "Desocupado", "Inactivo"),
      window       = "trimestral"
    )

    expect_true(file.exists(path))

    df <- readr::read_csv(path, show_col_types = FALSE)
    expect_true(all(c("from", "to", "weight", "id", "periodo_base",
                      "categoria", "periodo") %in% names(df)))
    expect_gt(nrow(df), 0)
  })
})


test_that("trimestral: periodos en formato 'YYYY_tA-tB'", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_panel.csv")

    regenerar_panel_historico(
      path_csv     = path,
      df_microdato = df_microdato,
      var          = "ESTADO",
      etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
      categorias   = c("Ocupado"),
      window       = "trimestral"
    )

    df <- readr::read_csv(path, show_col_types = FALSE)
    ### Fixture tiene 3 ondas (2024-T1, T2, T3) → 2 dúos consecutivos.
    expect_true(all(df$periodo %in% c("2024_t1-t2", "2024_t2-t3")))
  })
})


test_that("anual: periodos en formato 'YYYY_tN' (sin '-tM')", {
  ### Para anual necesitamos que el fixture tenga el mismo trimestre en
  ### años consecutivos. El fixture sintético tiene solo 2024 → no hay
  ### dúo anual válido. Construimos un microdato extendido.
  base <- load_panel_mock()

  ### Replicar el fixture con año 2025 (mismo schema, distintos valores)
  ### para tener al menos un dúo anual válido (2024-T1 → 2025-T1).
  df_2025 <- base |>
    dplyr::filter(TRIMESTRE == 1L) |>
    dplyr::mutate(ANO4 = 2025L)
  df_microdato <- dplyr::bind_rows(base, df_2025) |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_panel_anual.csv")

    regenerar_panel_historico(
      path_csv     = path,
      df_microdato = df_microdato,
      var          = "ESTADO",
      etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
      categorias   = c("Ocupado"),
      window       = "anual"
    )

    df <- readr::read_csv(path, show_col_types = FALSE)
    ### Periodo formato anual: solo "2024_t1" (sin "-tN").
    expect_true(all(df$periodo == "2024_t1"))
  })
})


test_that("idempotencia: segunda corrida no agrega duplicados", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_panel.csv")

    regenerar_panel_historico(
      path_csv     = path,
      df_microdato = df_microdato,
      var          = "ESTADO",
      etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
      categorias   = c("Ocupado"),
      window       = "trimestral"
    )
    n_primera <- nrow(readr::read_csv(path, show_col_types = FALSE))

    ### Segunda corrida: no debe agregar nada (todos los periodos
    ### ya existen en periodos_existentes).
    regenerar_panel_historico(
      path_csv     = path,
      df_microdato = df_microdato,
      var          = "ESTADO",
      etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
      categorias   = c("Ocupado"),
      window       = "trimestral"
    )
    n_segunda <- nrow(readr::read_csv(path, show_col_types = FALSE))

    expect_equal(n_segunda, n_primera)
  })
})


test_that("schema: weight numérico, periodo character, categoria character", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_panel.csv")

    regenerar_panel_historico(
      path_csv     = path,
      df_microdato = df_microdato,
      var          = "ESTADO",
      etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
      categorias   = c("Ocupado", "Desocupado"),
      window       = "trimestral"
    )

    df <- readr::read_csv(path, show_col_types = FALSE)
    expect_type(df$weight, "double")
    expect_type(df$periodo, "character")
    expect_type(df$categoria, "character")
    expect_type(df$from, "character")
    expect_type(df$to, "character")
  })
})


test_that("invariante: porcentajes (weight) en rango [0, 100]", {
  df_microdato <- load_panel_mock() |> agrega_vars_derivadas()

  withr::with_tempdir({
    path <- file.path(getwd(), "test_panel.csv")

    regenerar_panel_historico(
      path_csv     = path,
      df_microdato = df_microdato,
      var          = "ESTADO",
      etiquetas    = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
      categorias   = c("Ocupado", "Desocupado", "Inactivo"),
      window       = "trimestral"
    )

    df <- readr::read_csv(path, show_col_types = FALSE)
    expect_true(all(df$weight >= 0))
    expect_true(all(df$weight <= 100))
  })
})
