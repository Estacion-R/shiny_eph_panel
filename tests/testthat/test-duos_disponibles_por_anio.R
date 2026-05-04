### Tests de duos_disponibles_por_anio() (en ETL/99-functions.R).
###
### Devuelve los dúos válidos para un año dado (chequeando que ambos
### extremos del panel existan en periodos_disponibles). Acepta
### parámetro `window` que cambia formato y lógica de pareo.

test_that("trimestral devuelve choices clásicos cuando todos los extremos existen", {
  ### Mock de periodos_disponibles con 2024 completo + 2025-T1 (para que
  ### t4-t1 sea válido).
  periodos <- tibble::tibble(
    ANO4      = c(2024L, 2024L, 2024L, 2024L, 2025L),
    TRIMESTRE = c(1L, 2L, 3L, 4L, 1L)
  )

  duos <- duos_disponibles_por_anio(2024, periodos, window = "trimestral")

  expect_equal(names(duos), c("1-2", "2-3", "3-4", "4-1"))
  expect_equal(unname(duos), c(1L, 2L, 3L, 4L))
})


test_that("trimestral filtra duos cuando el extremo no está", {
  ### Sin 2025-T1 → dúo 4-1 inválido.
  periodos <- tibble::tibble(
    ANO4      = c(2024L, 2024L, 2024L, 2024L),
    TRIMESTRE = c(1L, 2L, 3L, 4L)
  )

  duos <- duos_disponibles_por_anio(2024, periodos, window = "trimestral")

  expect_equal(names(duos), c("1-2", "2-3", "3-4"))
  expect_false("4-1" %in% names(duos))
})


test_that("anual devuelve labels T1/T2/T3/T4 cuando hay año siguiente completo", {
  periodos <- tibble::tibble(
    ANO4      = c(2024L, 2024L, 2024L, 2024L,
                  2025L, 2025L, 2025L, 2025L),
    TRIMESTRE = c(1L, 2L, 3L, 4L,
                  1L, 2L, 3L, 4L)
  )

  duos <- duos_disponibles_por_anio(2024, periodos, window = "anual")

  expect_equal(names(duos), c("T1", "T2", "T3", "T4"))
  expect_equal(unname(duos), c(1L, 2L, 3L, 4L))
})


test_that("anual: año sin t+1 disponible → vector vacío", {
  ### 2025 es el último año disponible, no hay 2026 → ningún dúo
  ### anual válido para anio_0=2025.
  periodos <- tibble::tibble(
    ANO4      = c(2024L, 2024L, 2024L, 2024L,
                  2025L, 2025L, 2025L, 2025L),
    TRIMESTRE = c(1L, 2L, 3L, 4L,
                  1L, 2L, 3L, 4L)
  )

  duos <- duos_disponibles_por_anio(2025, periodos, window = "anual")

  expect_length(duos, 0)
})


test_that("anual: año parcial con t+1 disponible solo para algunos trim", {
  ### 2024 completo + 2025 solo T1, T2 → dúos anuales válidos solo T1, T2.
  periodos <- tibble::tibble(
    ANO4      = c(2024L, 2024L, 2024L, 2024L,
                  2025L, 2025L),
    TRIMESTRE = c(1L, 2L, 3L, 4L,
                  1L, 2L)
  )

  duos <- duos_disponibles_por_anio(2024, periodos, window = "anual")

  expect_equal(names(duos), c("T1", "T2"))
  expect_equal(unname(duos), c(1L, 2L))
})


test_that("default window = trimestral", {
  periodos <- tibble::tibble(
    ANO4      = c(2024L, 2024L, 2024L, 2024L, 2025L),
    TRIMESTRE = c(1L, 2L, 3L, 4L, 1L)
  )

  ### Sin pasar window → debe comportarse como trimestral.
  duos <- duos_disponibles_por_anio(2024, periodos)

  expect_equal(names(duos), c("1-2", "2-3", "3-4", "4-1"))
})
