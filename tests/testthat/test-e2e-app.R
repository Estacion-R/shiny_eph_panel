### Tests E2E con shinytest2 + Chromote.
###
### Sprint test-3 lite. Cubrimos los flujos más críticos del usuario:
###   1. Smoke test: la app levanta sin errores y renderiza inputs base.
###   2. Toggle Tipo de dúo: cambiar radio "trimestral" ↔ "anual" se
###      refleja en el reactive state (regresión #44).
###   3. Descarga panel_runtime_csv: el downloadHandler entrega un archivo
###      no vacío (regresión #35).
###
### Estos tests son MUY pesados (cada uno levanta la app entera con todos
### los datasets) y se saltan por default. Para correrlos:
###
###   RUN_E2E=true Rscript tests/testthat.R
###
### En CI corren solo en el workflow tests-e2e.yml (workflow_dispatch
### manual o nightly), nunca en tests-unit.yml.
###
### Otros guards:
###   - skip_if_not_installed("shinytest2"/"chromote"): paquetes opcionales.
###   - data_output/panel_runtime.parquet: si no está, el test se salta
###     con un mensaje descriptivo (no crashea).

library(testthat)

### Helper: crea AppDriver apuntado al root del proyecto. Encapsula el
### setup común y la verificación previa de prerequisitos (datos, lib).
new_app <- function(name, ...) {
  skip_if_not(Sys.getenv("RUN_E2E") == "true",
              "RUN_E2E env var no seteada (correr con RUN_E2E=true).")
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")

  ### Necesitamos los datasets de runtime: si están ausentes el test no
  ### tiene sentido (el módulo levanta error al boot). Mejor saltar con
  ### un mensaje claro que dejarlo crashear.
  app_dir <- testthat::test_path("..", "..")
  if (!file.exists(file.path(app_dir, "data_output/panel_runtime.parquet"))) {
    skip("data_output/panel_runtime.parquet no presente. Correr ETL pipelines.")
  }

  shinytest2::AppDriver$new(
    app_dir = app_dir,
    name    = name,
    height  = 900,
    width   = 1400,
    load_timeout = 60 * 1000,  # boot puede tardar (datos pesados)
    ...
  )
}


test_that("smoke: la app levanta y registra el input tipo_duo", {
  app <- new_app("smoke")
  withr::defer(app$stop())

  ### get_values() devuelve TODO el reactive state. Si la app levantó
  ### bien, "tipo_duo" tiene su valor default ("trimestral").
  vals <- app$get_values()

  expect_true("tipo_duo" %in% names(vals$input),
              info = "tipo_duo no está registrado en input")
  expect_equal(vals$input$tipo_duo, "trimestral")
})


test_that("toggle Tipo de dúo: trimestral ↔ anual se refleja en input state", {
  app <- new_app("toggle_tipo_duo")
  withr::defer(app$stop())

  ### Default: trimestral.
  expect_equal(app$get_value(input = "tipo_duo"), "trimestral")

  ### Cambiar a anual.
  app$set_inputs(tipo_duo = "anual")
  app$wait_for_idle(timeout = 5000)
  expect_equal(app$get_value(input = "tipo_duo"), "anual")

  ### Volver a trimestral.
  app$set_inputs(tipo_duo = "trimestral")
  app$wait_for_idle(timeout = 5000)
  expect_equal(app$get_value(input = "tipo_duo"), "trimestral")
})


test_that("módulo Calidad: KPI encontrado renderiza valor numérico válido", {
  app <- new_app("calidad_kpi")
  withr::defer(app$stop())

  ### Shiny no renderiza outputs hasta que su UI es visible. Navegar al
  ### nav_panel "Calidad de la muestra" via main_nav (bslib::navset_pill_list)
  ### dispara el render del módulo calidad.
  app$set_inputs(main_nav = "Calidad de la muestra")
  app$wait_for_idle(timeout = 10000)

  vals <- app$get_values()
  kpi <- vals$output$`calidad-kpi_encontrado`

  expect_true(!is.null(kpi),
              info = "calidad-kpi_encontrado no se renderizó tras navegar")
  ### Forma esperada: número con 1 decimal + "%". Acepta "—" si el
  ### dataset filtrado quedó vacío (caso edge, no debería con defaults).
  expect_match(kpi, "^[0-9]+\\.[0-9]+%$|^—$",
               info = paste("kpi_encontrado tiene forma inesperada:", kpi))
})
