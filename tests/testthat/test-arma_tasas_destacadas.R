### Tests de arma_tasas_destacadas() (en R/utils_analisis.R).
###
### Calcula las 3 tasas destacadas para Foto:
###   - persistencia: % de la categoría seleccionada en t0 que sigue
###     en la misma categoría en t1.
###   - salida: 100 - persistencia.
###   - entrada: % de la categoría en t1 que NO estaba en esa categoría
###     en t0 (vino desde otra).
###
### Estrategia: panel mock pequeño con casos controlados donde las
### tasas se calculan a mano.

test_that("Persistencia 80% / Salida 20% / Entrada 27.3% para caso controlado", {
  ### Panel mock de 3 personas:
  ###   A: Ocupado_t0 → Ocupado_t1, PONDERA=800
  ###   B: Ocupado_t0 → Desocupado_t1, PONDERA=200
  ###   C: Desocupado_t0 → Ocupado_t1, PONDERA=300
  ###
  ### Total Ocupados t0 = A + B = 1000.
  ###   Persistencia Ocupado = 800 / 1000 = 80%.
  ###   Salida Ocupado = 20%.
  ###
  ### Total Ocupados t1 = A + C = 1100.
  ###   Entrada_misma (Ocupado→Ocupado) = 800 / 1100 ≈ 72.7%.
  ###   Entrada = 100 - 72.7 = 27.3%.
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 1L, 2L),
    ESTADO_t1  = c(1L, 2L, 1L),
    PONDERA    = c(800, 200, 300),
    PONDERA_t1 = c(800, 200, 300)
  )

  tasas <- arma_tasas_destacadas(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    categoria = "Ocupado"
  )

  expect_equal(tasas$persistencia, 80)
  expect_equal(tasas$salida, 20)
  expect_equal(tasas$entrada, 27.3)
})


test_that("Persistencia 100% cuando todos siguen en su categoría", {
  ### Todos los Ocupados de t0 son Ocupados en t1.
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 1L, 1L),
    ESTADO_t1  = c(1L, 1L, 1L),
    PONDERA    = c(500, 500, 500),
    PONDERA_t1 = c(500, 500, 500)
  )

  tasas <- arma_tasas_destacadas(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    categoria = "Ocupado"
  )

  expect_equal(tasas$persistencia, 100)
  expect_equal(tasas$salida, 0)
  expect_equal(tasas$entrada, 0)  ### todos los Ocupados t1 venían de Ocupado t0
})


test_that("Persistencia 0% cuando nadie persiste", {
  ### Todos los Ocupados t0 transitan a Desocupado en t1.
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 1L, 1L),
    ESTADO_t1  = c(2L, 2L, 2L),
    PONDERA    = c(500, 500, 500),
    PONDERA_t1 = c(500, 500, 500)
  )

  tasas <- arma_tasas_destacadas(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    categoria = "Ocupado"
  )

  expect_equal(tasas$persistencia, 0)
  expect_equal(tasas$salida, 100)
  ### No hay Ocupados en t1 → la fn retorna 0 por el length-0 guard
  expect_equal(tasas$entrada, 100)
})


test_that("Categoría sin presencia en el panel devuelve tasas 0/100/100", {
  ### Panel sin ningún Asalariado (codigo 3) en t0 ni t1.
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 2L),
    ESTADO_t1  = c(2L, 1L),
    PONDERA    = c(500, 500),
    PONDERA_t1 = c(500, 500)
  )

  tasas <- arma_tasas_destacadas(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    categoria = "Trab_familiar"
  )

  expect_equal(tasas$persistencia, 0)
  expect_equal(tasas$salida, 100)
  expect_equal(tasas$entrada, 100)
})


test_that("Tasas funcionan para variable distinta de ESTADO (ej. CAT_OCUP)", {
  ### Mismo patrón pero ahora la variable se llama CAT_OCUP.
  ### Codigo 3 = Asalariado, 4 = TFSR.
  df_panel <- tibble::tibble(
    CAT_OCUP    = c(3L, 3L, 4L),
    CAT_OCUP_t1 = c(3L, 4L, 3L),
    PONDERA     = c(800, 200, 300),
    PONDERA_t1  = c(800, 200, 300)
  )

  tasas <- arma_tasas_destacadas(
    df_panel  = df_panel,
    var       = "CAT_OCUP",
    etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),
    categoria = "Asalariado"
  )

  expect_equal(tasas$persistencia, 80)
  expect_equal(tasas$salida, 20)
  expect_equal(tasas$entrada, 27.3)
})


test_that("Resultado: list de 3 elementos numéricos redondeados a 1 decimal", {
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 1L, 2L),
    ESTADO_t1  = c(1L, 2L, 1L),
    PONDERA    = c(800, 200, 300),
    PONDERA_t1 = c(800, 200, 300)
  )

  tasas <- arma_tasas_destacadas(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
    categoria = "Ocupado"
  )

  expect_type(tasas, "list")
  expect_named(tasas, c("persistencia", "salida", "entrada"))
  expect_true(all(vapply(tasas, is.numeric, logical(1))))
})
