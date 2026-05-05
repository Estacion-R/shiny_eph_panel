### Tests de duo_label() (en R/mod_calidad_panel.R).
###
### Helper que construye el código de dupla a partir de (trim_0, trim_1).
### En staging actual (v0.8.1) la firma es duo_label(t0, t1) y siempre
### devuelve "tN-tM". El parámetro `window` se sumó en v0.9.0 (PR #60
### pendiente de merge). Cuando se mergee, sumar tests del modo anual.

### Cargar la función desde el módulo. duo_label es top-level (fuera del
### moduleServer), por eso source-ear el archivo expone la fn.
source(testthat::test_path("..", "..", "R", "mod_calidad_panel.R"))


test_that("duo_label construye 'tN-tM' a partir de (t0, t1)", {
  expect_equal(duo_label(1, 2), "t1-t2")
  expect_equal(duo_label(2, 3), "t2-t3")
  expect_equal(duo_label(3, 4), "t3-t4")
  expect_equal(duo_label(4, 1), "t4-t1")
})


test_that("duo_label vectorizado: acepta vectores de t0 y t1", {
  expect_equal(
    duo_label(c(1, 2, 3), c(2, 3, 4)),
    c("t1-t2", "t2-t3", "t3-t4")
  )
})
