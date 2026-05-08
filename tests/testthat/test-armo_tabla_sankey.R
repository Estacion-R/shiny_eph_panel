### Tests de armo_tabla_sankey() (en ETL/99-functions.R).
###
### Función defensive contra tablas vacías (parche del hotfix v0.7.0
### cuando el render del sankey rompía durante transiciones del toggle
### tipo_duo).

test_that("armo_tabla_sankey con tabla vacía devuelve schema esperado", {
  vacia <- tibble::tibble(
    ESTADO       = character(),
    ESTADO_t1    = character(),
    porc_base    = numeric(),
    id           = character(),
    periodo_base = character()
  )

  out <- armo_tabla_sankey(vacia, categoria = "Ocupado")

  expect_equal(nrow(out), 0)
  expect_true(all(c("from", "to", "weight", "id", "periodo_base", "categoria")
                  %in% names(out)))
})


test_that("armo_tabla_sankey con tabla NULL/sin filas no rompe", {
  ### Caso edge: tabla vacía sin la columna periodo_base. Igual no debe
  ### tirar el error 'argumento tiene longitud cero'.
  vacia <- tibble::tibble()

  expect_error(armo_tabla_sankey(vacia, categoria = "Ocupado"), NA)
})


test_that("armo_tabla_sankey filtra por categoria correctamente (t_anterior)", {
  ### Construir una tabla con 2 categorías (Ocupado, Desocupado) en t0.
  ### El filter debe devolver solo las filas con from = "Ocupado_tant".
  tabla <- tibble::tibble(
    ESTADO       = c("Ocupado_tant", "Ocupado_tant",
                     "Desocupado_tant", "Desocupado_tant"),
    ESTADO_t1    = c("Ocupado_tpost", "Desocupado_tpost",
                     "Ocupado_tpost", "Desocupado_tpost"),
    porc_base    = c(85, 5, 30, 70),
    id           = c("a", "b", "c", "d"),
    periodo_base = c("t_anterior", "t_anterior",
                     "t_anterior", "t_anterior")
  )

  out <- armo_tabla_sankey(tabla, categoria = "Ocupado")

  ### Debe quedar solo las 2 filas que parten de Ocupado.
  expect_equal(nrow(out), 2)
  expect_true(all(out$from == "Ocupado_t0"))
  ### El reemplazo "_tant" → "_t0" debe haberse aplicado.
  expect_true(all(grepl("_t0|_t1", out$from)))
  expect_true(all(grepl("_t0|_t1", out$to)))
  ### Categoría agregada como columna.
  expect_true(all(out$categoria == "Ocupado"))
})


test_that("armo_tabla_sankey con periodo_base=t_posterior filtra por to", {
  tabla <- tibble::tibble(
    ESTADO       = c("Ocupado_tant", "Desocupado_tant"),
    ESTADO_t1    = c("Ocupado_tpost", "Ocupado_tpost"),
    porc_base    = c(85, 30),
    id           = c("a", "c"),
    periodo_base = c("t_posterior", "t_posterior")
  )

  out <- armo_tabla_sankey(tabla, categoria = "Ocupado")

  expect_equal(nrow(out), 2)
  expect_true(all(out$to == "Ocupado_t1"))
})
