### Tests de mod_analisis_server() (en R/mod_analisis.R) — issue #79.
###
### Estrategia: shiny::testServer() para blindar la reactividad del módulo
### central de análisis ANTES y DESPUÉS del refactor de rendimiento (sacar
### los reactives del observe() para recuperar la memoización de
### df_eph_panel).
###
### Tres clases de test:
###   A) Derivación del dúo (anio_post/trim_post): INVARIANTE. Debe pasar
###      pre y post refactor (el refactor no puede cambiar la aritmética).
###   B) Outputs de tasas destacadas: INVARIANTE. Mismo valor pre y post.
###   C) Memoización de df_eph_panel: cambiar input$periodo_base (sentido del
###      Sankey) NO debe recomputar el panel. FALLA pre-refactor (df_eph_panel
###      vive dentro del observe y se recrea en cada invalidación) y PASA
###      post-refactor. El control positivo verifica que cambiar el año SÍ
###      recomputa (no rompimos la dependencia real).
###
### Para correr:
###   Rscript tests/testthat.R   (o RUN_E2E=true ... para la suite completa)
###
### Guards: armo_base_panel toca el panel runtime (Arrow) que no está en el
### entorno de tests; lo mockeamos. gt + highcharter sólo se necesitan para
### registrar los renders al init del módulo → skip si no están instalados
### (en CI tests-unit el entorno mínimo no los trae; corre local + e2e env).

library(testthat)

skip_if_not_installed("shiny")
skip_if_not_installed("gt")          # output$matriz_transicion usa gt::render_gt al init

### El runner (tests/testthat.R) no source-ea el módulo ni los configs.
source(testthat::test_path("..", "..", "R", "mod_analisis.R"))
source(testthat::test_path("..", "..", "R", "configs_analisis.R"))

### Stub de renderHighchart (sin namespace en el módulo). Lo reemplazamos por
### un renderUI(NULL): así los bodies de Sankey/línea/tasas no se ejecutan en
### el test (no necesitamos la pipeline de highcharter ni los datasets
### históricos) pero el output queda registrado. Mismo patrón que el test de
### calidad.
if (!exists("renderHighchart", envir = .GlobalEnv, mode = "function")) {
  assign(
    "renderHighchart",
    function(expr, ...) shiny::renderUI({ NULL }),
    envir = .GlobalEnv
  )
}

### --- Setup de mocks: globales + funciones caras ------------------------
###
### Devuelve un entorno con el contador de llamadas a armo_base_panel.
### Restaura las funciones reales (NO rm) para no contaminar otros tests.
mock_analisis_globals <- function(env = parent.frame()) {
  contador <- new.env()
  contador$abp <- 0L

  ### Periodos/años disponibles (2023-2025, 4 trimestres). Sirven para los
  ### observers de selectInputs y para tasas_anio_ant.
  periodos <- tibble::tibble(
    ANO4      = rep(c(2023L, 2024L, 2025L), each = 4),
    TRIMESTRE = rep(1:4, times = 3)
  )

  ### armo_base_panel mock: cuenta llamadas y devuelve panel vacío (0 filas).
  ### El conteo es lo que nos importa; arma_tasas_destacadas está mockeada y
  ### el Sankey corta en req(nrow > 0).
  mock_abp <- function(anio_0, trimestre_0, anio_1 = NULL, trimestre_1 = NULL,
                       df = NULL, variables = NULL, window = "trimestral") {
    contador$abp <- contador$abp + 1L
    tibble::tibble()
  }

  ### arma_tasas_destacadas mock: fuerza df_panel (para que df_eph_panel() se
  ### evalúe de verdad y el contador suba) y devuelve tasas fijas.
  mock_atd <- function(df_panel, var, etiquetas, categoria) {
    invisible(nrow(df_panel))  # fuerza la promesa df_eph_panel()
    list(persistencia = 50, salida = 10, entrada = 5)
  }

  orig <- list(
    armo_base_panel       = get("armo_base_panel", envir = .GlobalEnv),
    arma_tasas_destacadas = get("arma_tasas_destacadas", envir = .GlobalEnv)
  )

  assign("periodos_disponibles", periodos, envir = .GlobalEnv)
  assign("anios_disponibles", c(2023L, 2024L, 2025L), envir = .GlobalEnv)
  ### Versiones anuales: no se tocan en modo trimestral, pero las dejamos
  ### definidas por las dudas (0 filas).
  assign("periodos_disponibles_anual", periodos[0, ], envir = .GlobalEnv)
  assign("anios_disponibles_anual", integer(0), envir = .GlobalEnv)
  assign("armo_base_panel", mock_abp, envir = .GlobalEnv)
  assign("arma_tasas_destacadas", mock_atd, envir = .GlobalEnv)

  withr::defer({
    assign("armo_base_panel", orig$armo_base_panel, envir = .GlobalEnv)
    assign("arma_tasas_destacadas", orig$arma_tasas_destacadas, envir = .GlobalEnv)
    rm("periodos_disponibles", "anios_disponibles",
       "periodos_disponibles_anual", "anios_disponibles_anual",
       envir = .GlobalEnv)
  }, envir = env)

  contador
}


### --- A) Derivación del dúo (anio_post / trim_post) ----------------------

test_that("derivación del dúo: trim 1-3 mismo año, trim 4 cruza de año", {
  mock_analisis_globals()

  ### Config con pob_n_fn override que expone la derivación como string.
  cfg <- config_cond_act
  cfg$pob_n_fn <- function(input, anio_ant, trim_ant, anio_post, trim_post,
                           tipo_duo, var_panel = NULL, definicion = NULL) {
    paste(anio_ant, trim_ant, anio_post, trim_post)
  }

  shiny::testServer(
    mod_analisis_server,
    args = list(config = cfg, tipo_duo = shiny::reactive("trimestral")),
    expr = {
      ### Trimestre 1: post = mismo año, trimestre +1.
      session$setInputs(anio_ant = "2024", trimestre_ant = "1",
                        category = "Ocupado", periodo_base = "t_posterior")
      expect_equal(output$pob_n, "2024 1 2024 2")

      ### Trimestre 4: post = año +1, trimestre 1.
      session$setInputs(trimestre_ant = "4")
      expect_equal(output$pob_n, "2024 4 2025 1")
    }
  )
})


### --- B) Outputs de tasas destacadas (invariante) -----------------------

test_that("tasas destacadas: los value boxes formatean el % de cada tasa", {
  mock_analisis_globals()

  shiny::testServer(
    mod_analisis_server,
    args = list(config = config_cond_act,
                tipo_duo = shiny::reactive("trimestral")),
    expr = {
      session$setInputs(anio_ant = "2024", trimestre_ant = "1",
                        category = "Ocupado", periodo_base = "t_posterior")
      expect_equal(output$tasa_persistencia, "50%")
      expect_equal(output$tasa_salida, "10%")
      expect_equal(output$tasa_entrada, "5%")
    }
  )
})


### --- C) Memoización de df_eph_panel (FALLA pre-refactor) ----------------

test_that("memoización: cambiar el sentido (periodo_base) NO recomputa el panel", {
  contador <- mock_analisis_globals()

  shiny::testServer(
    mod_analisis_server,
    args = list(config = config_cond_act,
                tipo_duo = shiny::reactive("trimestral")),
    expr = {
      session$setInputs(anio_ant = "2024", trimestre_ant = "1",
                        category = "Ocupado", periodo_base = "t_posterior")
      invisible(output$tasa_persistencia)  # fuerza tasas() -> df_eph_panel()
      n1 <- contador$abp
      expect_gt(n1, 0)  # sanity: el panel se computó al menos una vez

      ### Cambiar SOLO el sentido del Sankey. df_eph_panel no depende de
      ### periodo_base: post-refactor el panel queda cacheado (n2 == n1).
      ### Pre-refactor el observe se reejecuta, recrea el reactive y vuelve a
      ### llamar armo_base_panel (n2 > n1) -> este expect FALLA pre-refactor.
      session$setInputs(periodo_base = "t_anterior")
      invisible(output$tasa_persistencia)
      n2 <- contador$abp
      expect_equal(n2, n1)

      ### Control positivo: cambiar el AÑO sí debe recomputar el panel.
      session$setInputs(anio_ant = "2025")
      invisible(output$tasa_persistencia)
      n3 <- contador$abp
      expect_gt(n3, n2)
    }
  )
})
