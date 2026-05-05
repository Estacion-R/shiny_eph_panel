### Tests de arma_matriz_transicion() (en R/utils_analisis.R).
###
### Construye una matriz NxN de transición (porcentaje sobre el total t0
### de cada fila) usando preparo_base() con periodo_base = "t_anterior".
###
### Output: tibble con `from` como primera col y una col por categoría
### destino. Valores en porcentaje, deberían sumar ~100 por fila (con
### tolerancia por redondeo a 1 decimal).

test_that("arma_matriz_transicion: estructura del output", {
  ### Panel mínimo controlado:
  ###   3 personas Ocupado_t0 → 2 Ocupado_t1 + 1 Desocupado_t1
  ###   2 personas Desocupado_t0 → 1 Ocupado_t1 + 1 Inactivo_t1
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 1L, 1L, 2L, 2L),
    ESTADO_t1  = c(1L, 1L, 2L, 1L, 3L),
    PONDERA    = c(500, 500, 500, 500, 500),
    PONDERA_t1 = c(500, 500, 500, 500, 500)
  )

  matriz <- arma_matriz_transicion(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar")
  )

  expect_s3_class(matriz, "tbl_df")
  expect_true("from" %in% names(matriz))
  ### Etiquetas legibles aplicadas: "Ocupado" → "Ocupados", etc.
  expect_true(all(c("Ocupados", "Desocupados", "Inactivos",
                    "Trab. familiares") %in% names(matriz)))
})


test_that("arma_matriz_transicion: filas suman ~100% (tolerancia redondeo)", {
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 1L, 1L, 2L, 2L),
    ESTADO_t1  = c(1L, 1L, 2L, 1L, 3L),
    PONDERA    = c(500, 500, 500, 500, 500),
    PONDERA_t1 = c(500, 500, 500, 500, 500)
  )

  matriz <- arma_matriz_transicion(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar")
  )

  ### Sumar todas las cols numéricas por fila. Tolerancia ±0.5 pp por
  ### redondeo a 1 decimal en preparo_base.
  cols_num <- setdiff(names(matriz), "from")
  sumas <- rowSums(matriz[, cols_num])
  expect_true(all(abs(sumas - 100) < 1))
})


test_that("arma_matriz_transicion: valores específicos para caso controlado", {
  ### Panel:
  ###   2 Ocupado_t0 → Ocupado_t1 (PONDERA 500 c/u → 1000)
  ###   1 Ocupado_t0 → Desocupado_t1 (PONDERA 500)
  ###   Total Ocupado_t0 = 1500 → 1000/1500 = 66.7%, 500/1500 = 33.3%
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 1L, 1L),
    ESTADO_t1  = c(1L, 1L, 2L),
    PONDERA    = c(500, 500, 500),
    PONDERA_t1 = c(500, 500, 500)
  )

  matriz <- arma_matriz_transicion(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar")
  )

  fila_ocup <- matriz |> dplyr::filter(from == "Ocupados")
  expect_equal(fila_ocup$Ocupados, 66.7)
  expect_equal(fila_ocup$Desocupados, 33.3)
  expect_equal(fila_ocup$Inactivos, 0)
})


test_that("arma_matriz_transicion: orden de filas y cols sigue 'etiquetas' (no alfabético)", {
  ### Panel con las 4 categorías presentes para que aparezcan las 4 filas.
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 2L, 3L, 4L),
    ESTADO_t1  = c(1L, 2L, 3L, 4L),
    PONDERA    = c(500, 500, 500, 500),
    PONDERA_t1 = c(500, 500, 500, 500)
  )

  ### Etiquetas en orden NO alfabético: Inactivo, Ocupado, Desocupado, ...
  matriz <- arma_matriz_transicion(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Inactivo", "Ocupado", "Desocupado", "Trab_familiar")
  )

  ### Filas: el factor con levels = remap(etiquetas) define el orden,
  ### dplyr::arrange(from, to) lo respeta.
  expect_equal(matriz$from, c("Inactivos", "Ocupados", "Desocupados",
                              "Trab. familiares"))
  ### Cols (después de "from"): mismo orden.
  cols <- setdiff(names(matriz), "from")
  expect_equal(cols, c("Inactivos", "Ocupados", "Desocupados",
                       "Trab. familiares"))
})


test_that("arma_matriz_transicion: funciona con CAT_OCUP", {
  ### Mismo schema pero variable CAT_OCUP. Códigos 1=Patron, 2=Cuenta_propia,
  ### 3=Asalariado, 4=TFSR.
  df_panel <- tibble::tibble(
    CAT_OCUP    = c(3L, 3L, 2L),
    CAT_OCUP_t1 = c(3L, 3L, 3L),
    PONDERA     = c(500, 500, 500),
    PONDERA_t1  = c(500, 500, 500)
  )

  matriz <- arma_matriz_transicion(
    df_panel  = df_panel,
    var       = "CAT_OCUP",
    etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR")
  )

  ### Etiquetas legibles esperadas según el mapeo de la función.
  expect_true(all(c("Patrones", "Cuenta propia", "Asalariados",
                    "Trab. familiares") %in% names(matriz)))
})


test_that("arma_matriz_transicion: categoría sin presencia → no aparece como fila pero SÍ como columna", {
  ### Sin Trab_familiar en el panel: la columna existe con 0s gracias a
  ### names_expand = TRUE + factor con levels en `to`. Pero la fila NO
  ### se genera (no hay registros que la tengan como `from`).
  df_panel <- tibble::tibble(
    ESTADO     = c(1L, 2L, 3L),
    ESTADO_t1  = c(1L, 2L, 3L),
    PONDERA    = c(500, 500, 500),
    PONDERA_t1 = c(500, 500, 500)
  )

  matriz <- arma_matriz_transicion(
    df_panel  = df_panel,
    var       = "ESTADO",
    etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar")
  )

  ### Columna "Trab. familiares" presente y todo 0 (no hay transiciones
  ### hacia esa categoría en el panel).
  expect_true("Trab. familiares" %in% names(matriz))
  expect_true(all(matriz[["Trab. familiares"]] == 0))

  ### Pero la fila NO se genera (no hay nadie con ESTADO=4 en t0).
  expect_false("Trab. familiares" %in% matriz$from)
  expect_equal(nrow(matriz), 3)
})
