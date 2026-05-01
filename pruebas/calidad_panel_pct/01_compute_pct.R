### -----------------------------------------------------------------------
### Prototipo issue #36 — paso 1: computar % de personas-panel encontradas
### Output: pruebas/calidad_panel_pct/output/pct_encontrado_historico.csv
###
### Para cada par trimestral consecutivo (t0 → t1) calcula:
###   - n_t0 / pondera_t0:    filas y población expandida del trimestre base
###   - n_panel / pondera_panel: filas y población expandida que matchearon
###   - pct_encontrado_n / pct_encontrado_pondera: cocientes en %
###
### Corre desde la raíz del proyecto:
###   source("pruebas/calidad_panel_pct/01_compute_pct.R")
### -----------------------------------------------------------------------

source("ETL/00-libraries.R")
source("ETL/99-functions.R")
source("ETL/01-extract.R")

library(purrr)

### Pares (t0, t1) consecutivos disponibles en el microdato. Replico el
### patrón de regenerar_panel_historico() para mantener consistencia con
### los CSV históricos del proyecto.
pares_trimestrales <- df_eph_full |>
  distinct(ANO4, TRIMESTRE) |>
  arrange(ANO4, TRIMESTRE) |>
  collect() |>
  mutate(
    anio_post = if_else(TRIMESTRE %in% 1:3, ANO4, ANO4 + 1L),
    trim_post = if_else(TRIMESTRE %in% 1:3, TRIMESTRE + 1L, 1L)
  ) |>
  semi_join(
    df_eph_full |>
      distinct(ANO4, TRIMESTRE) |>
      collect() |>
      rename(anio_post = ANO4, trim_post = TRIMESTRE),
    by = join_by(anio_post, trim_post)
  ) |>
  mutate(periodo = glue("{ANO4}_t{TRIMESTRE}-t{trim_post}"))

cat(glue("Pares trimestrales disponibles: {nrow(pares_trimestrales)}\n\n"))

### Para un par (t0, t1) computa los conteos y el % de pareo.
### Usa armo_base_panel() del proyecto, que delega en eph::organize_panels().
compute_pct_par <- function(anio_0, trim_0, anio_post, trim_post, periodo) {

  cat(glue("  procesando {periodo}... "))

  ### Total de la muestra t0 (universo válido: ESTADO ∈ 1..4, descarta 0
  ### que son "Entrevista no realizada / no aplica").
  base_t0 <- df_eph_full |>
    filter(ANO4 == anio_0, TRIMESTRE == trim_0, ESTADO %in% 1:4) |>
    select(PONDERA) |>
    collect()

  panel <- armo_base_panel(
    anio_0      = anio_0,
    trimestre_0 = trim_0,
    anio_1      = anio_post,
    trimestre_1 = trim_post
  ) |>
    filter(ESTADO %in% 1:4)

  out <- tibble(
    periodo            = periodo,
    anio_0             = anio_0,
    trim_0             = trim_0,
    anio_1             = anio_post,
    trim_1             = trim_post,
    n_t0               = nrow(base_t0),
    pondera_t0         = sum(base_t0$PONDERA, na.rm = TRUE),
    n_panel            = nrow(panel),
    pondera_panel      = sum(panel$PONDERA, na.rm = TRUE)
  ) |>
    mutate(
      pct_encontrado_n       = round(n_panel / n_t0 * 100, 2),
      pct_encontrado_pondera = round(pondera_panel / pondera_t0 * 100, 2)
    )

  cat(glue("OK ({out$n_panel}/{out$n_t0} = {out$pct_encontrado_n}%)\n"))
  out
}

historico_pct <- pares_trimestrales |>
  pmap(\(ANO4, TRIMESTRE, anio_post, trim_post, periodo)
       compute_pct_par(ANO4, TRIMESTRE, anio_post, trim_post, periodo)) |>
  list_rbind()

dir.create("pruebas/calidad_panel_pct/output", showWarnings = FALSE,
           recursive = TRUE)

readr::write_csv(historico_pct,
                 "pruebas/calidad_panel_pct/output/pct_encontrado_historico.csv")

cat(glue("\nListo. {nrow(historico_pct)} filas en pruebas/calidad_panel_pct/output/pct_encontrado_historico.csv\n"))
cat(glue("Rango pct_encontrado_n: {min(historico_pct$pct_encontrado_n)}% .. {max(historico_pct$pct_encontrado_n)}%\n"))
