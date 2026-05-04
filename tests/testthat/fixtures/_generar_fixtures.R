### Generador del fixture sintético `panel_mock.rds`.
###
### Correr UNA SOLA VEZ desde la raíz del proyecto:
###   Rscript tests/testthat/fixtures/_generar_fixtures.R
###
### El output `panel_mock.rds` SÍ se versiona. Este script se versiona
### para reproducibilidad (semillas fijas) pero no se ejecuta en CI.
###
### Diseño:
### - 100 individuos en 3 ondas trimestrales (2024-T1, T2, T3).
### - CODUSU + NRO_HOGAR + COMPONENTE controlados: cada individuo
###   aparece en exactamente las 3 ondas (panel balanceado para tests).
### - Distribuciones de variables EPH controladas pero realistas:
###     ESTADO: ~50% Ocupados, ~5% Desocupados, ~40% Inactivos, ~5% Menor.
###     CAT_OCUP (entre Ocupados): ~75% Asalariado, ~15% Cuenta propia,
###       ~5% Patrón, ~5% TFSR.
###     PP07H (entre Asalariados): ~65% formal, ~35% informal.
###     PP05I y PP05K solo desde 2024-T1 (no NA en este mock).
###     CH04 y CH06 invariantes en t0 → t1 (con +0/+1 para edad).

library(dplyr)
library(tibble)

set.seed(20260504)

n_individuos <- 100L

### Generar individuos con metadata fija (sexo, edad inicial, categoría).
individuos <- tibble(
  CODUSU      = sprintf("USU%05d", seq_len(n_individuos)),
  NRO_HOGAR   = 1L,
  COMPONENTE  = 1L,
  CH04_fija   = sample(1:2, n_individuos, replace = TRUE),  # sexo
  CH06_inicial = sample(18:75, n_individuos, replace = TRUE)
)

### Para cada individuo, generar su trayectoria laboral en las 3 ondas.
generar_trayectoria <- function(id) {
  est_inicial <- sample(1:4, 1, prob = c(0.50, 0.05, 0.40, 0.05))

  ### Markov simple: la mayoría persiste, alguno transita.
  trans <- function(estado_actual) {
    if (estado_actual == 1) sample(1:4, 1, prob = c(0.85, 0.05, 0.08, 0.02))
    else if (estado_actual == 2) sample(1:4, 1, prob = c(0.30, 0.50, 0.20, 0.00))
    else if (estado_actual == 3) sample(1:4, 1, prob = c(0.10, 0.05, 0.85, 0.00))
    else 4L
  }

  e1 <- est_inicial
  e2 <- trans(e1)
  e3 <- trans(e2)

  c(e1, e2, e3)
}

estados <- vapply(seq_len(n_individuos), generar_trayectoria, integer(3))

### Generar categoría ocupacional para Ocupados, NA para resto.
gen_cat_ocup <- function(estado) {
  if (estado == 1L) sample(1:4, 1, prob = c(0.05, 0.15, 0.75, 0.05))
  else NA_integer_
}

### Generar PP07H (descuento jubilatorio) solo para Asalariados.
gen_pp07h <- function(cat_ocup) {
  if (!is.na(cat_ocup) && cat_ocup == 3L) {
    sample(1:2, 1, prob = c(0.65, 0.35))
  } else {
    NA_integer_
  }
}

### Generar PP05I (monotributo cuenta propia) y PP05K (aportes propios)
### solo para Cuenta propia + Patrón.
gen_pp05 <- function(cat_ocup, prob_si) {
  if (!is.na(cat_ocup) && cat_ocup %in% c(1L, 2L)) {
    sample(1:2, 1, prob = c(prob_si, 1 - prob_si))
  } else {
    NA_integer_
  }
}

trimestres <- list(
  list(ANO4 = 2024L, TRIMESTRE = 1L),
  list(ANO4 = 2024L, TRIMESTRE = 2L),
  list(ANO4 = 2024L, TRIMESTRE = 3L)
)

ondas <- purrr::map(seq_along(trimestres), function(t) {
  individuos |>
    mutate(
      ANO4      = trimestres[[t]]$ANO4,
      TRIMESTRE = trimestres[[t]]$TRIMESTRE,
      CH04      = CH04_fija,
      CH06      = CH06_inicial + (t - 1L),  # edad sube 1 año con t (simplificación)
      ESTADO    = estados[t, ],
      CAT_OCUP  = vapply(estados[t, ], gen_cat_ocup, integer(1)),
      PP07H     = vapply(.data$CAT_OCUP, gen_pp07h, integer(1)),
      PP05I     = vapply(.data$CAT_OCUP, gen_pp05, integer(1), prob_si = 0.30),
      PP05K     = vapply(.data$CAT_OCUP, gen_pp05, integer(1), prob_si = 0.40),
      PONDERA   = sample(800:1500, n_individuos, replace = TRUE)
    ) |>
    select(-CH04_fija, -CH06_inicial)
}) |>
  bind_rows()

### Verificación rápida.
stopifnot(nrow(ondas) == n_individuos * 3)
stopifnot(all(c("ANO4", "TRIMESTRE", "CODUSU", "NRO_HOGAR", "COMPONENTE",
                "CH04", "CH06", "ESTADO", "CAT_OCUP",
                "PP07H", "PP05I", "PP05K", "PONDERA") %in% names(ondas)))

dir.create("tests/testthat/fixtures", showWarnings = FALSE, recursive = TRUE)
saveRDS(ondas, "tests/testthat/fixtures/panel_mock.rds")

cat("Fixture generada: tests/testthat/fixtures/panel_mock.rds\n")
cat("  Filas:", nrow(ondas), "\n")
cat("  Individuos únicos:", dplyr::n_distinct(ondas$CODUSU), "\n")
cat("  Ondas:", paste(unique(paste0(ondas$ANO4, "-T", ondas$TRIMESTRE)),
                      collapse = ", "), "\n")
