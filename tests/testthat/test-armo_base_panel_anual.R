### Tests de armo_base_panel(window = "anual") (en ETL/99-functions.R).
###
### Modo runtime anual: lee data_output/panel_runtime_anual.parquet ON-DEMAND
### con filter pushdown sobre (anio_0, trim_0). Hotfix v0.7.3 cambió de
### arrow::read_parquet (carga el archivo entero) a arrow::open_dataset
### (truly lazy, footprint mínimo).
###
### Estrategia: generar un parquet sintético chico en with_tempdir(), apuntar
### PATH_PANEL_RUNTIME_ANUAL a ese path, y verificar:
###   - filter pushdown sobre (anio_0, trim_0) devuelve solo el dúo pedido.
###   - columnas anio_0/trim_0 se dropean del output (no contaminan el
###     downstream que espera ESTADO, ESTADO_t1, etc.).
###   - error claro cuando el parquet no existe.

build_fixture_anual_parquet <- function(path) {
  ### Schema mínimo del panel_runtime_anual.parquet. Incluye 3 dúos
  ### sintéticos con valores diferenciables para verificar el filter.
  fixture <- dplyr::bind_rows(
    tibble::tibble(
      anio_0 = 2022L, trim_0 = 1L,
      CODUSU = c("A", "B"),
      ESTADO    = c(1L, 2L),
      ESTADO_t1 = c(1L, 1L),
      PONDERA    = c(500, 600),
      PONDERA_t1 = c(500, 600)
    ),
    tibble::tibble(
      anio_0 = 2022L, trim_0 = 2L,
      CODUSU = c("C", "D", "E"),
      ESTADO    = c(1L, 1L, 3L),
      ESTADO_t1 = c(1L, 3L, 3L),
      PONDERA    = c(700, 800, 900),
      PONDERA_t1 = c(700, 800, 900)
    ),
    tibble::tibble(
      anio_0 = 2023L, trim_0 = 1L,
      CODUSU = "F",
      ESTADO    = 1L,
      ESTADO_t1 = 1L,
      PONDERA    = 1000,
      PONDERA_t1 = 1000
    )
  )
  arrow::write_parquet(fixture, path)
  invisible(fixture)
}


test_that("armo_base_panel modo anual: filter pushdown sobre (anio_0, trim_0)", {
  withr::with_tempdir({
    path <- file.path(getwd(), "panel_anual.parquet")
    build_fixture_anual_parquet(path)

    ### Inyectar el path como global, simulando 01-extract.R en runtime.
    withr::local_options(list())
    assign("PATH_PANEL_RUNTIME_ANUAL", path, envir = .GlobalEnv)
    withr::defer(rm("PATH_PANEL_RUNTIME_ANUAL", envir = .GlobalEnv))

    out <- armo_base_panel(
      anio_0      = 2022,
      trimestre_0 = 2,
      window      = "anual"
    )

    expect_s3_class(out, "tbl_df")
    ### Solo las 3 filas del dúo 2022-T2.
    expect_equal(nrow(out), 3)
    expect_setequal(out$CODUSU, c("C", "D", "E"))
  })
})


test_that("armo_base_panel modo anual: dropea las cols anio_0/trim_0 del output", {
  withr::with_tempdir({
    path <- file.path(getwd(), "panel_anual.parquet")
    build_fixture_anual_parquet(path)

    assign("PATH_PANEL_RUNTIME_ANUAL", path, envir = .GlobalEnv)
    withr::defer(rm("PATH_PANEL_RUNTIME_ANUAL", envir = .GlobalEnv))

    out <- armo_base_panel(
      anio_0      = 2022,
      trimestre_0 = 1,
      window      = "anual"
    )

    expect_false("anio_0" %in% names(out))
    expect_false("trim_0" %in% names(out))
    ### Las cols del panel sí están.
    expect_true(all(c("ESTADO", "ESTADO_t1", "PONDERA", "PONDERA_t1") %in% names(out)))
  })
})


test_that("armo_base_panel modo anual: dúo no presente devuelve 0 filas", {
  withr::with_tempdir({
    path <- file.path(getwd(), "panel_anual.parquet")
    build_fixture_anual_parquet(path)

    assign("PATH_PANEL_RUNTIME_ANUAL", path, envir = .GlobalEnv)
    withr::defer(rm("PATH_PANEL_RUNTIME_ANUAL", envir = .GlobalEnv))

    out <- armo_base_panel(
      anio_0      = 2099,  # año inexistente
      trimestre_0 = 1,
      window      = "anual"
    )

    expect_equal(nrow(out), 0)
  })
})


test_that("armo_base_panel modo anual: error claro si no existe el parquet", {
  withr::with_tempdir({
    ### No creamos el parquet; apuntamos a un path inexistente.
    path_fake <- file.path(getwd(), "no_existe.parquet")
    assign("PATH_PANEL_RUNTIME_ANUAL", path_fake, envir = .GlobalEnv)
    withr::defer(rm("PATH_PANEL_RUNTIME_ANUAL", envir = .GlobalEnv))

    expect_error(
      armo_base_panel(anio_0 = 2022, trimestre_0 = 1, window = "anual"),
      "panel_runtime_anual.parquet no encontrado"
    )
  })
})


test_that("armo_base_panel modo runtime: error si window no es trimestral ni anual", {
  expect_error(
    armo_base_panel(anio_0 = 2022, trimestre_0 = 1, window = "diario"),
    "window debe ser 'trimestral' o 'anual'"
  )
})


test_that("armo_base_panel modo trimestral runtime: error si df_panel_runtime no existe", {
  ### Caso defensivo: en CI no hay df_panel_runtime cargado. Verifica que
  ### el mensaje sea informativo (apunta a 01-extract.R como remediación).
  if (exists("df_panel_runtime", envir = .GlobalEnv)) {
    skip("df_panel_runtime ya cargado en este entorno")
  }

  expect_error(
    armo_base_panel(anio_0 = 2022, trimestre_0 = 1, window = "trimestral"),
    "df_panel_runtime no disponible"
  )
})
