### Tests del Armador de panel (#77, #78).
###
### Estrategia: testear las FUNCIONES PURAS del módulo (R/mod_armador.R) sin
### levantar Shiny. El filtrado se extrajo a armador_filtrar() justo para esto.
### El flujo completo de UI (preview gt + descarga + reactivos) se cubre en el
### e2e con shinytest2 (test-e2e-app.R), porque gt/reactable no están en el env
### mínimo de los tests unitarios.
###
### tests/testthat.R no source-ea el módulo; lo traemos acá. NO sourceamos
### panel_descarga.R (su contenido UI top-level necesita bsicons, ausente en el
### env mínimo de tests). columnas_panel_runtime se mockea donde hace falta.
source(testthat::test_path("..", "..", "R", "mod_armador.R"))


### --- Mock: panel runtime sintético (esquema de 32 cols, con AGLOMERADO) ---
### 10 filas controladas para aseverar conteos exactos. as_arrow_table() para
### que armador_filtrar() opere en modo lazy igual que en producción.
mock_panel_df <- function() {
  tibble::tibble(
    anio_0      = c(2024, 2024, 2024, 2025, 2025, 2025, 2025, 2024, 2025, 2024),
    trim_0      = c(1L, 1L, 2L, 1L, 2L, 3L, 3L, 3L, 1L, 2L),
    CODUSU      = sprintf("U%03d", 1:10),
    NRO_HOGAR   = rep(1, 10),
    COMPONENTE  = 1:10,
    ANO4        = c(2024, 2024, 2024, 2025, 2025, 2025, 2025, 2024, 2025, 2024),
    TRIMESTRE   = c(1L, 1L, 2L, 1L, 2L, 3L, 3L, 3L, 1L, 2L),
    CH04        = c(1, 2, 2, 1, 2, 1, 2, 1, 2, 1),
    CH06        = c(20, 35, 50, 14, 67, 30, 45, 8, 99, 25),
    ESTADO      = c(1, 1, 2, 3, 1, 1, 2, 4, 1, 3),
    CAT_OCUP    = c(3, 3, 0, 0, 1, 3, 0, 0, 2, 0),
    PP07H       = c(1, 2, 0, 0, 1, 1, 0, 0, 2, 0),
    PP05I       = rep(0L, 10),
    PP05K       = rep(0L, 10),
    formalidad  = c(1L, 2L, NA, NA, 1L, 1L, NA, NA, 2L, NA),
    formalidad_ampliada = c(1L, 2L, NA, NA, 1L, 1L, NA, NA, 2L, NA),
    PONDERA     = rep(100, 10),
    AGLOMERADO  = c(32, 33, 2, 32, 0, 13, 32, 33, 2, 0),
    Periodo     = rep("2024_t1-t2", 10),
    ANO4_t1     = c(2024, 2024, 2024, 2025, 2025, 2025, 2025, 2024, 2025, 2024),
    TRIMESTRE_t1 = c(2L, 2L, 3L, 2L, 3L, 4L, 4L, 4L, 2L, 3L),
    CH04_t1     = c(1, 2, 2, 1, 2, 1, 2, 1, 2, 1),
    CH06_t1     = c(20, 35, 50, 14, 67, 30, 45, 8, 99, 25) + 1,
    ESTADO_t1   = c(1, 2, 1, 1, 1, 2, 3, 4, 1, 1),
    CAT_OCUP_t1 = c(3, 0, 3, 0, 1, 0, 0, 0, 2, 3),
    PP07H_t1    = rep(0, 10),
    PP05I_t1    = rep(0L, 10),
    PP05K_t1    = rep(0L, 10),
    formalidad_t1 = rep(NA_integer_, 10),
    formalidad_ampliada_t1 = rep(NA_integer_, 10),
    PONDERA_t1  = rep(100, 10),
    consistencia = rep(TRUE, 10)
  )
}

mock_panel_arrow <- function() arrow::as_arrow_table(mock_panel_df())

### nrow de la query lazy ya colectada.
n_filt <- function(q) nrow(dplyr::collect(q))


### -------------------------------------------------------------------------
### armador_filtrar(): la lógica de filtrado server-side
### -------------------------------------------------------------------------

test_that("armador_filtrar sin filtros devuelve el panel completo", {
  expect_equal(n_filt(armador_filtrar(mock_panel_arrow())), 10)
})

test_that("armador_filtrar: sexo, año, trimestre, aglomerado (estables t0)", {
  df <- mock_panel_df(); ds <- mock_panel_arrow()
  expect_equal(n_filt(armador_filtrar(ds, sexo = "2")),
               sum(df$CH04 == 2))
  expect_equal(n_filt(armador_filtrar(ds, anios = c("2024", "2025"))), 10)
  expect_equal(n_filt(armador_filtrar(ds, anios = "2025")),
               sum(df$anio_0 == 2025))
  expect_equal(n_filt(armador_filtrar(ds, trims = c("1", "3"))),
               sum(df$trim_0 %in% c(1, 3)))
  expect_equal(n_filt(armador_filtrar(ds, aglos = c("32", "33"))),
               sum(df$AGLOMERADO %in% c(32, 33)))
})

test_that("armador_filtrar: edad en rango completo es no-op; movida filtra", {
  df <- mock_panel_df(); ds <- mock_panel_arrow()
  ### Rango completo (0..110) = no aplica filtro.
  expect_equal(n_filt(armador_filtrar(ds, edad = c(ARMADOR_EDAD_MIN, ARMADOR_EDAD_MAX))), 10)
  ### 25..50 filtra por CH06 (t0).
  expect_equal(n_filt(armador_filtrar(ds, edad = c(25, 50))),
               sum(df$CH06 >= 25 & df$CH06 <= 50))
})

test_that("armador_filtrar: el toggle t0/t1 elige la columna de ESTADO/CAT_OCUP", {
  df <- mock_panel_df(); ds <- mock_panel_arrow()
  expect_equal(n_filt(armador_filtrar(ds, momento = "t0", condact = "1")),
               sum(df$ESTADO == 1))
  expect_equal(n_filt(armador_filtrar(ds, momento = "t1", condact = "1")),
               sum(df$ESTADO_t1 == 1))
  expect_equal(n_filt(armador_filtrar(ds, momento = "t0", catocup = "3")),
               sum(df$CAT_OCUP == 3))
  expect_equal(n_filt(armador_filtrar(ds, momento = "t1", catocup = "3")),
               sum(df$CAT_OCUP_t1 == 3))
})

test_that("armador_filtrar combina con AND entre variables", {
  df <- mock_panel_df(); ds <- mock_panel_arrow()
  q <- armador_filtrar(ds, anios = "2025", trims = "3", momento = "t0", condact = "2")
  expect_equal(n_filt(q),
               sum(df$anio_0 == 2025 & df$trim_0 == 3 & df$ESTADO == 2))
})


### -------------------------------------------------------------------------
### armador_nombres_salida(): esquema de salida _t0/_t1
### -------------------------------------------------------------------------

test_that("armador_nombres_salida descarta anio_0/trim_0 y sufija _t0", {
  out <- armador_nombres_salida(mock_panel_df())
  expect_false(any(c("anio_0", "trim_0") %in% names(out)))
  expect_true(all(c("ESTADO_t0", "CAT_OCUP_t0", "CH04_t0", "ANO4_t0",
                    "PONDERA_t0") %in% names(out)))
  expect_true(all(c("ESTADO_t1", "CAT_OCUP_t1") %in% names(out)))
  ### Claves, AGLOMERADO (fijo) y consistencia NO llevan sufijo.
  expect_true(all(c("CODUSU", "NRO_HOGAR", "COMPONENTE", "Periodo",
                    "AGLOMERADO", "consistencia") %in% names(out)))
  expect_false("AGLOMERADO_t0" %in% names(out))
  expect_equal(ncol(out), ncol(mock_panel_df()) - 2L)
})

test_that("armador_diccionario_salida coincide con el esquema de salida", {
  ### Mock mínimo del diccionario canónico (vive en panel_descarga.R).
  cmock <- tibble::tribble(
    ~Variable,    ~Descripción,
    "anio_0",     "x", "trim_0", "x", "ANO4", "x",
    "ESTADO",     "x", "AGLOMERADO", "x", "consistencia", "x"
  )
  assign("columnas_panel_runtime", cmock, envir = .GlobalEnv)
  withr::defer(rm("columnas_panel_runtime", envir = .GlobalEnv))

  dic <- armador_diccionario_salida()
  expect_false(any(c("anio_0", "trim_0") %in% dic$Variable))
  expect_true("ESTADO_t0" %in% dic$Variable)   # var t0 → sufijada
  expect_true("AGLOMERADO" %in% dic$Variable)   # fija → sin sufijo
})


### -------------------------------------------------------------------------
### armador_etiquetar(): códigos → texto en t0 y t1
### -------------------------------------------------------------------------

test_that("armador_etiquetar pone etiquetas EPH en t0 y t1 + AGLOMERADO", {
  et <- armador_etiquetar(mock_panel_df())
  expect_true(is.factor(et$ESTADO) || is.character(et$ESTADO))
  expect_true(any(grepl("Ocupado", as.character(et$ESTADO))))
  expect_true(any(grepl("Ocupado", as.character(et$ESTADO_t1))))   # t1 también
  expect_true(any(grepl("Varon|Varón", as.character(et$CH04))))
  ### AGLOMERADO: 32 -> Ciudad de Buenos Aires.
  expect_true(any(grepl("Buenos Aires", as.character(et$AGLOMERADO))))
  ### formalidad custom -> Formal/Informal.
  expect_true(all(as.character(stats::na.omit(et$formalidad)) %in% c("Formal", "Informal")))
})


### -------------------------------------------------------------------------
### armador_frase_filtros(): resumen en lenguaje natural
### -------------------------------------------------------------------------

test_that("armador_frase_filtros arma el caso típico (toggle t0)", {
  f <- armador_frase_filtros("trimestral", "t0", anios = "2025", trims = "1",
                             sexo = "2", edad = c(0L, 110L),
                             condact = "1", catocup = "3")
  expect_match(f, "Situación en el trimestre 2 de 2025")
  expect_match(f, "las mujeres de todas las edades")
  expect_match(f, "ocupadas y asalariadas")
})

test_that("armador_frase_filtros: sin filtros = panel completo", {
  f <- armador_frase_filtros("trimestral", "t0", character(0), character(0),
                             character(0), c(0L, 110L), character(0), character(0))
  expect_match(f, "panel intertrimestral completo")
})

test_that("armador_frase_filtros: toggle t1 cambia el marco a origen", {
  f <- armador_frase_filtros("trimestral", "t1", anios = "2025", trims = "1",
                             sexo = character(0), edad = c(0L, 110L),
                             condact = "1", catocup = character(0))
  expect_match(f, "al inicio del dúo")
  expect_match(f, "al cierre del dúo eran")
})

test_that("armador_frase_filtros: género masculino sólo con Varón", {
  f <- armador_frase_filtros("trimestral", "t0", "2024", "1", sexo = "1",
                             edad = c(0L, 110L), condact = "2", catocup = character(0))
  expect_match(f, "los varones")
  expect_match(f, "desocupados")
})

test_that("armador_frase_filtros: incluye cláusula de aglomerado", {
  f <- armador_frase_filtros("trimestral", "t0", "2025", "1", character(0),
                             c(0L, 110L), character(0), character(0),
                             aglos = c("32", "33"))
  expect_match(f, "en .*Buenos Aires|Partidos")
})


### -------------------------------------------------------------------------
### Totales del embudo + formato
### -------------------------------------------------------------------------

test_that("armador_totales_periodo suma n_t0 y n_panel del período", {
  df_cal <- tibble::tibble(
    anio_0 = c(2024L, 2024L, 2025L), trim_0 = c(1L, 2L, 1L),
    n_t0 = c(1000L, 2000L, 3000L), n_panel = c(400L, 900L, 1500L)
  )
  assign("df_calidad_panel", df_cal, envir = .GlobalEnv)
  withr::defer(rm("df_calidad_panel", envir = .GlobalEnv))

  ### Sin período → totales globales.
  tot <- armador_totales_periodo("trimestral", character(0), character(0))
  expect_equal(tot$t0, 6000); expect_equal(tot$match, 2800)
  ### Filtrado a 2024 → suma sólo esos dúos.
  tot24 <- armador_totales_periodo("trimestral", "2024", character(0))
  expect_equal(tot24$t0, 3000); expect_equal(tot24$match, 1300)
})

test_that("armador_fmt_pct: 1 decimal es-AR, <0,1% y NA", {
  expect_equal(armador_fmt_pct(44.34), "44,3%")
  expect_equal(armador_fmt_pct(0.03), "<0,1%")
  expect_equal(armador_fmt_pct(NA_real_), "—")
})


### -------------------------------------------------------------------------
### Aglomerados + último período + opciones de año
### -------------------------------------------------------------------------

test_that("armador_aglo_nombres mapea códigos y maneja el 0 / desconocidos", {
  n <- armador_aglo_nombres(c(32, 0, 99999))
  expect_match(n[1], "Bs\\. As\\.")          # 32 = Ciudad de Bs. As. (dicc eph)
  expect_equal(n[2], "Sin clasificar (0)")    # 0 = fallback
  expect_equal(n[3], "Aglomerado 99999")      # desconocido = fallback genérico
})

test_that("armador_ultimo_periodo devuelve el dúo más reciente", {
  df_cal <- tibble::tibble(anio_0 = c(2024L, 2025L, 2025L),
                           trim_0 = c(4L, 1L, 3L),
                           n_t0 = 1L, n_panel = 1L)
  assign("df_calidad_panel", df_cal, envir = .GlobalEnv)
  withr::defer(rm("df_calidad_panel", envir = .GlobalEnv))
  ult <- armador_ultimo_periodo("trimestral")
  expect_equal(ult$anio, 2025L)
  expect_equal(ult$trim, 3L)
})

test_that("armador_anios_opciones devuelve años ordenados del dataset", {
  assign("anios_disponibles", c(2025L, 2003L, 2010L), envir = .GlobalEnv)
  withr::defer(rm("anios_disponibles", envir = .GlobalEnv))
  expect_equal(armador_anios_opciones("trimestral"), c(2003L, 2010L, 2025L))
})
