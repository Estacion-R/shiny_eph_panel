### Tests de mod_calidad_panel_server() (en R/mod_calidad_panel.R).
###
### Estrategia: shiny::testServer() para testear los reactives expuestos
### por el módulo. Limitaciones documentadas (ver ROADMAP.md):
###   - testServer() NO refleja updateSelectInput() en session$input.
###     Tests que dependen de eso → diferidos a Sprint test-3 (shinytest2).
###
### Lo que SÍ podemos verificar acá:
###   - Switch del dataset según tipo_duo() (df_calidad_actual()).
###   - datos_filtrados() respondiendo a input$anios e input$duos.
###   - Outputs KPI (kpi_encontrado, kpi_inc_total, kpi_inc_sexo,
###     kpi_inc_edad) calculando promedios sobre el filtro.

### tests/testthat.R no source-ea mod_calidad_panel.R; lo hacemos acá.
source(testthat::test_path("..", "..", "R", "mod_calidad_panel.R"))

### Stubs para renderers UI-only que no nos interesa testear acá pero
### que el moduleServer evalúa al inicializar (output$hc_calidad <-
### renderHighchart(...)). Sin estos stubs, testServer falla con
### "no se pudo encontrar la función renderHighchart" porque highcharter
### no está cargado en el environment minimal de los tests.
###
### Los stubs solo proveen una signature compatible; el contenido del
### render no se ejecuta a menos que accedamos al output, y nuestros
### tests solo acceden a outputs renderText (kpi_*).
if (!exists("renderHighchart", envir = .GlobalEnv, mode = "function")) {
  assign(
    "renderHighchart",
    function(expr, ...) shiny::renderUI({ NULL }),
    envir = .GlobalEnv
  )
}

### --- Mocks de los datasets globales que consume el módulo ----------------
###
### El módulo lee df_calidad_panel y df_calidad_panel_anual del global env
### (via 01-extract.R en la app real). Para tests inyectamos versiones
### mínimas controladas. withr::defer asegura cleanup tras cada test.

mock_calidad_globals <- function(env = parent.frame()) {
  ### Schema de calidad_panel_pct_historico.csv (subset de cols usadas).
  df_trim <- tibble::tibble(
    periodo                = c("2024_t1-t2", "2024_t2-t3", "2024_t3-t4"),
    anio_0                 = c(2024L, 2024L, 2024L),
    trim_0                 = c(1L, 2L, 3L),
    anio_1                 = c(2024L, 2024L, 2024L),
    trim_1                 = c(2L, 3L, 4L),
    pct_encontrado_n       = c(50.0, 60.0, 70.0),
    pct_encontrado_pondera = c(48.0, 58.0, 68.0),
    pct_inc_total          = c(4.0, 5.0, 6.0),
    pct_inc_sexo           = c(1.0, 1.5, 2.0),
    pct_inc_edad           = c(8.0, 9.0, 10.0)
  )

  df_anual <- tibble::tibble(
    periodo                = c("2024_t1", "2024_t2"),
    anio_0                 = c(2024L, 2024L),
    trim_0                 = c(1L, 2L),
    anio_1                 = c(2025L, 2025L),
    trim_1                 = c(1L, 2L),
    pct_encontrado_n       = c(40.0, 42.0),
    pct_encontrado_pondera = c(39.0, 41.0),
    pct_inc_total          = c(5.0, 6.0),    # mean = 5.5 (sin ambigüedad IEEE)
    pct_inc_sexo           = c(1.2, 1.4),    # mean = 1.3
    pct_inc_edad           = c(5.5, 5.7)     # mean = 5.6
  )

  ### Asignar a global con cleanup auto.
  assign("df_calidad_panel", df_trim, envir = .GlobalEnv)
  assign("df_calidad_panel_anual", df_anual, envir = .GlobalEnv)
  withr::defer(rm("df_calidad_panel", envir = .GlobalEnv), envir = env)
  withr::defer(rm("df_calidad_panel_anual", envir = .GlobalEnv), envir = env)

  list(trim = df_trim, anual = df_anual)
}


### --- Tests --------------------------------------------------------------

test_that("df_calidad_actual() devuelve dataset trimestral por default", {
  mocks <- mock_calidad_globals()

  shiny::testServer(
    mod_calidad_panel_server,
    args = list(tipo_duo = shiny::reactive("trimestral")),
    expr = {
      session$setInputs(duos = "todas", anios = c(2024, 2024))
      ### df_calidad_actual() debe devolver el dataset trimestral.
      df <- df_calidad_actual()
      expect_equal(nrow(df), 3)
      expect_equal(df$periodo, c("2024_t1-t2", "2024_t2-t3", "2024_t3-t4"))
    }
  )
})


test_that("df_calidad_actual() devuelve dataset anual cuando tipo_duo='anual'", {
  mocks <- mock_calidad_globals()

  shiny::testServer(
    mod_calidad_panel_server,
    args = list(tipo_duo = shiny::reactive("anual")),
    expr = {
      session$setInputs(duos = "todas", anios = c(2024, 2024))
      df <- df_calidad_actual()
      expect_equal(nrow(df), 2)
      expect_equal(df$periodo, c("2024_t1", "2024_t2"))
    }
  )
})


test_that("datos_filtrados() respeta rango anios", {
  mocks <- mock_calidad_globals()

  ### Extender el mock para tener años distintos.
  df_multi_anio <- dplyr::bind_rows(
    mocks$trim,
    tibble::tibble(
      periodo = "2025_t1-t2", anio_0 = 2025L, trim_0 = 1L,
      anio_1 = 2025L, trim_1 = 2L,
      pct_encontrado_n = 75, pct_encontrado_pondera = 73,
      pct_inc_total = 7, pct_inc_sexo = 2.5, pct_inc_edad = 11
    )
  )
  assign("df_calidad_panel", df_multi_anio, envir = .GlobalEnv)

  shiny::testServer(
    mod_calidad_panel_server,
    args = list(tipo_duo = shiny::reactive("trimestral")),
    expr = {
      session$setInputs(duos = "todas", anios = c(2024, 2024))
      df <- datos_filtrados()
      expect_true(all(df$anio_0 == 2024))
      expect_equal(nrow(df), 3)

      session$setInputs(anios = c(2025, 2025))
      df <- datos_filtrados()
      expect_true(all(df$anio_0 == 2025))
      expect_equal(nrow(df), 1)
    }
  )
})


test_that("datos_filtrados() respeta selección de dúos específicos", {
  mocks <- mock_calidad_globals()

  shiny::testServer(
    mod_calidad_panel_server,
    args = list(tipo_duo = shiny::reactive("trimestral")),
    expr = {
      session$setInputs(duos = "t1-t2", anios = c(2024, 2024))
      df <- datos_filtrados()
      expect_equal(nrow(df), 1)
      ### periodo es factor (orden por anio_0/trim_0); comparar como char.
      expect_equal(as.character(df$periodo[1]), "2024_t1-t2")

      session$setInputs(duos = c("t1-t2", "t2-t3"))
      df <- datos_filtrados()
      expect_equal(nrow(df), 2)
    }
  )
})


test_that("datos_filtrados() con duos='todas' incluye todos los dúos del rango", {
  mocks <- mock_calidad_globals()

  shiny::testServer(
    mod_calidad_panel_server,
    args = list(tipo_duo = shiny::reactive("trimestral")),
    expr = {
      session$setInputs(duos = "todas", anios = c(2024, 2024))
      df <- datos_filtrados()
      expect_equal(nrow(df), 3)
    }
  )
})


test_that("KPI outputs: promedio sobre filtro activo (trimestral)", {
  mocks <- mock_calidad_globals()

  shiny::testServer(
    mod_calidad_panel_server,
    args = list(tipo_duo = shiny::reactive("trimestral")),
    expr = {
      session$setInputs(duos = "todas", anios = c(2024, 2024))

      ### Promedios esperados sobre las 3 filas trimestrales:
      ###   pct_encontrado_n: mean(50, 60, 70) = 60.0
      ###   pct_inc_total:    mean(4, 5, 6)    = 5.0
      ###   pct_inc_sexo:     mean(1, 1.5, 2)  = 1.5
      ###   pct_inc_edad:     mean(8, 9, 10)   = 9.0
      expect_equal(output$kpi_encontrado, "60.0%")
      expect_equal(output$kpi_inc_total, "5.0%")
      expect_equal(output$kpi_inc_sexo, "1.5%")
      expect_equal(output$kpi_inc_edad, "9.0%")
    }
  )
})


test_that("KPI outputs: cambian al filtrar por dúo específico", {
  mocks <- mock_calidad_globals()

  shiny::testServer(
    mod_calidad_panel_server,
    args = list(tipo_duo = shiny::reactive("trimestral")),
    expr = {
      session$setInputs(duos = "t1-t2", anios = c(2024, 2024))
      ### Solo la primera fila (50, 4, 1, 8).
      expect_equal(output$kpi_encontrado, "50.0%")
      expect_equal(output$kpi_inc_total, "4.0%")
      expect_equal(output$kpi_inc_sexo, "1.0%")
      expect_equal(output$kpi_inc_edad, "8.0%")
    }
  )
})


test_that("KPI outputs: '—' cuando el filtro deja 0 filas", {
  mocks <- mock_calidad_globals()

  shiny::testServer(
    mod_calidad_panel_server,
    args = list(tipo_duo = shiny::reactive("trimestral")),
    expr = {
      ### Año fuera de rango → 0 filas.
      session$setInputs(duos = "todas", anios = c(2030, 2030))
      expect_equal(output$kpi_encontrado, "—")
      expect_equal(output$kpi_inc_total, "—")
      expect_equal(output$kpi_inc_sexo, "—")
      expect_equal(output$kpi_inc_edad, "—")
    }
  )
})


test_that("KPI outputs: usar tipo_duo=anual cambia los valores", {
  mocks <- mock_calidad_globals()

  shiny::testServer(
    mod_calidad_panel_server,
    args = list(tipo_duo = shiny::reactive("anual")),
    expr = {
      session$setInputs(duos = "todas", anios = c(2024, 2024))

      ### Promedios sobre las 2 filas anuales:
      ###   pct_encontrado_n: mean(40, 42) = 41.0
      ###   pct_inc_total:    mean(5, 6)   = 5.5
      expect_equal(output$kpi_encontrado, "41.0%")
      expect_equal(output$kpi_inc_total, "5.5%")
    }
  )
})
