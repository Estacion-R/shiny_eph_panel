### Tests de utilidades pequeñas en R/utils_analisis.R:
###   - formato_delta(): formatea un delta en pp con flecha y signo.
###   - sankey_label_legible(): convierte códigos técnicos en labels legibles.
###   - sankey_nodes_orden(): construye lista de nodos para forzar orden vertical.

### --- formato_delta() ---------------------------------------------------

test_that("formato_delta: positivo > 0.05 muestra '↑ +X.X pp'", {
  expect_equal(formato_delta(1.2), "↑ +1.2 pp")
  expect_equal(formato_delta(0.1), "↑ +0.1 pp")
  expect_equal(formato_delta(15.7), "↑ +15.7 pp")
})

test_that("formato_delta: negativo < -0.05 muestra '↓ -X.X pp'", {
  expect_equal(formato_delta(-0.5), "↓ -0.5 pp")
  expect_equal(formato_delta(-3.4), "↓ -3.4 pp")
})

test_that("formato_delta: cerca de 0 muestra '= 0.0 pp'", {
  ### Umbral: |delta| <= 0.05 se considera sin cambio.
  expect_equal(formato_delta(0), "= 0.0 pp")
  expect_equal(formato_delta(0.04), "= 0.0 pp")
  expect_equal(formato_delta(-0.03), "= -0.0 pp")
})

test_that("formato_delta: NA o NULL devuelve 'sin comparación'", {
  expect_equal(formato_delta(NA), "sin comparación")
  expect_equal(formato_delta(NA_real_), "sin comparación")
  expect_equal(formato_delta(NULL), "sin comparación")
  expect_equal(formato_delta(numeric(0)), "sin comparación")
})


### --- sankey_label_legible() -------------------------------------------

test_that("sankey_label_legible: ESTADO codes mapean correctamente", {
  expect_equal(sankey_label_legible("Ocupado_t0"), "Ocupados (t0)")
  expect_equal(sankey_label_legible("Desocupado_t1"), "Desocupados (t1)")
  expect_equal(sankey_label_legible("Inactivo_t0"), "Inactivos (t0)")
  expect_equal(sankey_label_legible("Trab_familiar_t1"), "Trab. familiares (t1)")
})

test_that("sankey_label_legible: CAT_OCUP codes mapean correctamente", {
  expect_equal(sankey_label_legible("Patron_t0"), "Patrones (t0)")
  expect_equal(sankey_label_legible("Cuenta_propia_t1"), "Cuenta propia (t1)")
  expect_equal(sankey_label_legible("Asalariado_t0"), "Asalariados (t0)")
  expect_equal(sankey_label_legible("TFSR_t1"), "Trab. familiares (t1)")
})

test_that("sankey_label_legible: formalidad codes mapean correctamente", {
  expect_equal(sankey_label_legible("Formal_t0"), "Formales (t0)")
  expect_equal(sankey_label_legible("Informal_t1"), "Informales (t1)")
})

test_that("sankey_label_legible: vectorizado", {
  codigos <- c("Ocupado_t0", "Desocupado_t1", "Inactivo_t0")
  esperado <- c("Ocupados (t0)", "Desocupados (t1)", "Inactivos (t0)")
  expect_equal(sankey_label_legible(codigos), esperado)
})

test_that("sankey_label_legible: código no mapeado usa fallback (mantiene base)", {
  ### Si llega algo que no está en el mapeo, devuelve la base + sufijo
  ### sin transformar (en lugar de NA).
  expect_equal(sankey_label_legible("Otro_t0"), "Otro (t0)")
})


### --- sankey_nodes_orden() --------------------------------------------

test_that("sankey_nodes_orden: 4 categorías → 8 nodos (4 t0 + 4 t1)", {
  cats <- c("Ocupados", "Desocupados", "Inactivos", "Trab. familiares")
  nodos <- sankey_nodes_orden(cats)

  expect_length(nodos, 8)
  expect_true(all(vapply(nodos, is.list, logical(1))))
})

test_that("sankey_nodes_orden: primeros 4 nodos son columna 0 (t0), siguientes 4 columna 1 (t1)", {
  cats <- c("Ocupados", "Desocupados", "Inactivos", "Trab. familiares")
  nodos <- sankey_nodes_orden(cats)

  ### Columnas: primeros 4 = 0, últimos 4 = 1.
  cols <- vapply(nodos, function(n) n$column, numeric(1))
  expect_equal(cols, c(0, 0, 0, 0, 1, 1, 1, 1))

  ### IDs: primeros 4 con sufijo (t0), últimos 4 con (t1), respetando
  ### el orden del input (NO alfabético).
  ids <- vapply(nodos, function(n) n$id, character(1))
  expect_equal(ids[1:4], paste0(cats, " (t0)"))
  expect_equal(ids[5:8], paste0(cats, " (t1)"))
})

test_that("sankey_nodes_orden: respeta el orden del input (no alfabético)", {
  ### Si el input no está ordenado alfabéticamente, la función debe
  ### preservar ese orden (es la razón de existir de la fn).
  cats <- c("Patrones", "Cuenta propia", "Asalariados", "Trab. familiares")
  nodos <- sankey_nodes_orden(cats)
  ids_t0 <- vapply(nodos[1:4], function(n) n$id, character(1))
  expect_equal(ids_t0, paste0(cats, " (t0)"))
})
