### Tests de duo_label() (en R/mod_calidad_panel.R).
###
### Helper que construye el código de dupla a partir de (trim_0, trim_1).
### Acepta `window`: en trimestral devuelve "tN-tM", en anual devuelve "tN".

### Cargar la función desde el módulo. duo_label es top-level (fuera del
### moduleServer), por eso source-ear el archivo expone la fn.
source(testthat::test_path("..", "..", "R", "mod_calidad_panel.R"))


test_that("trimestral construye 'tN-tM' como label", {
  expect_equal(duo_label(1, 2, "trimestral"), "t1-t2")
  expect_equal(duo_label(2, 3, "trimestral"), "t2-t3")
  expect_equal(duo_label(3, 4, "trimestral"), "t3-t4")
  expect_equal(duo_label(4, 1, "trimestral"), "t4-t1")
})


test_that("anual ignora trim_1 y devuelve solo 'tN'", {
  expect_equal(duo_label(1, 1, "anual"), "t1")
  expect_equal(duo_label(2, 2, "anual"), "t2")
  expect_equal(duo_label(3, 3, "anual"), "t3")
  expect_equal(duo_label(4, 4, "anual"), "t4")
})


test_that("default es trimestral", {
  expect_equal(duo_label(1, 2), "t1-t2")
})


test_that("vectorizado: acepta vectores de t0 y t1", {
  expect_equal(
    duo_label(c(1, 2, 3), c(2, 3, 4), "trimestral"),
    c("t1-t2", "t2-t3", "t3-t4")
  )
  expect_equal(
    duo_label(c(1, 2, 3, 4), c(1, 2, 3, 4), "anual"),
    c("t1", "t2", "t3", "t4")
  )
})
