#!/usr/bin/env Rscript

### -----------------------------------------------------------------------
### 03-update_data.R
###
### Script idempotente que:
###   1) Lee el parquet local (data_raw/df_eph.parquet) y detecta el último
###      trimestre disponible.
###   2) Intenta descargar los trimestres siguientes desde INDEC vía {eph}.
###   3) Si hay nuevos trimestres, agrega las filas al parquet y regenera
###      los archivos derivados:
###         - data_output/df_tasas_mt.parquet
###         - data_output/panel_cond_act_historico.csv
###   4) Imprime un resumen y emite un código de salida:
###         - 0  si todo OK (haya o no datos nuevos)
###         - 1  si hubo error
###      Y escribe un archivo .new_periods.txt con los períodos agregados
###      (una línea por período) para que el GitHub Action sepa si commitear.
###
### Pensado para correr tanto local como en CI (GitHub Actions).
### -----------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
  library(eph)
  library(glue)
  library(purrr)
})

### Default de download.file() es 60s, que se queda corto para algunos
### trimestres pesados de INDEC (4-7 MB en redes lentas). 10 minutos es
### un colchón seguro.
options(timeout = 600)

source("ETL/99-functions.R")

### Variables del microdato que persistimos en el parquet.
### Las 9 originales soportan el análisis de Condición de actividad.
### CAT_OCUP + PP07H/J/K + PP05I/K para los análisis de Categoría ocupacional
### y Formal/Informal (epic #6 + issue #15).
vars_eph <- c("CODUSU", "NRO_HOGAR", "COMPONENTE", "ANO4", "TRIMESTRE",
              "CH04", "CH06", "ESTADO", "PONDERA",
              "CAT_OCUP", "PP07H", "PP07J", "PP07K",
              "PP05I", "PP05K",
              "AGLOMERADO")  ### #78: filtro Aglomerado en el Armador

path_parquet_raw <- "data_raw/df_eph.parquet"
path_parquet_tasas <- "data_output/df_tasas_mt.parquet"
path_panel_hist <- "data_output/panel_cond_act_historico.csv"
path_new_periods <- ".new_periods.txt"


### -----------------------------------------------------------------------
### 1. Leer parquet local y detectar último período disponible
### -----------------------------------------------------------------------

if (!file.exists(path_parquet_raw)) {
  stop("No existe ", path_parquet_raw,
       ". El bootstrap inicial debe correrse manualmente desde 01-extract.R")
}

df_eph_local <- read_parquet(path_parquet_raw) |> select(all_of(vars_eph))

periodos_locales <- df_eph_local |>
  distinct(ANO4, TRIMESTRE) |>
  arrange(ANO4, TRIMESTRE)

ultimo_anio_local <- max(periodos_locales$ANO4)
ultimo_trim_local <- periodos_locales |>
  filter(ANO4 == ultimo_anio_local) |>
  pull(TRIMESTRE) |>
  max()

cat(glue("Último período local: {ultimo_anio_local}-T{ultimo_trim_local}"), "\n")


### -----------------------------------------------------------------------
### 2. Construir lista de candidatos a descargar
###    (desde el siguiente al último local hasta el trimestre actual)
### -----------------------------------------------------------------------

anio_actual <- as.integer(format(Sys.Date(), "%Y"))

### Genera el grid completo (anio, trim) desde el siguiente al último local
### hasta el año actual. Filtramos por > último período local para evitar
### que ultimo_trim_local == 4 produzca un rango invertido (5:4).
candidatos <- expand.grid(ANO4 = ultimo_anio_local:anio_actual, TRIMESTRE = 1:4) |>
  as_tibble() |>
  filter(ANO4 > ultimo_anio_local |
           (ANO4 == ultimo_anio_local & TRIMESTRE > ultimo_trim_local)) |>
  arrange(ANO4, TRIMESTRE)

if (nrow(candidatos) == 0) {
  cat("No hay períodos candidatos a descargar (ya estamos al día).\n")
  writeLines(character(0), path_new_periods)
  quit(status = 0)
}

cat("Candidatos a descargar:\n")
print(candidatos)


### -----------------------------------------------------------------------
### 3. Intentar descargar cada candidato. Si falla, asumimos que todavía
###    no fue publicado por INDEC y continuamos.
### -----------------------------------------------------------------------

descargar_trimestre <- function(anio, trim) {
  tryCatch({
    df <- eph::get_microdata(year = anio, period = trim,
                             vars = vars_eph, type = "individual")

    if (!is.data.frame(df) || nrow(df) == 0) {
      return(NULL)
    }
    df |> select(all_of(vars_eph))
  }, error = function(e) {
    message(glue("  No disponible {anio}-T{trim}: {conditionMessage(e)}"))
    NULL
  })
}

descargas <- candidatos |>
  mutate(datos = map2(ANO4, TRIMESTRE, descargar_trimestre)) |>
  filter(!map_lgl(datos, is.null))

if (nrow(descargas) == 0) {
  cat("\nNingún período nuevo disponible en INDEC.\n")
  writeLines(character(0), path_new_periods)
  quit(status = 0)
}

cat("\nPeríodos descargados exitosamente:\n")
descargas |> select(ANO4, TRIMESTRE) |> print()


### -----------------------------------------------------------------------
### 4. Agregar al parquet raw + regenerar derivados
### -----------------------------------------------------------------------

df_eph_nuevo <- bind_rows(descargas$datos)

df_eph_full <- bind_rows(df_eph_local, df_eph_nuevo) |>
  distinct(CODUSU, NRO_HOGAR, COMPONENTE, ANO4, TRIMESTRE, .keep_all = TRUE) |>
  arrange(ANO4, TRIMESTRE)

write_parquet(df_eph_full, path_parquet_raw)
cat(glue("Actualizado {path_parquet_raw} ({nrow(df_eph_full)} filas)"), "\n")

### Regenerar tasas del mercado de trabajo
df_tasas <- df_eph_full |>
  summarise(pob_total     = sum(PONDERA),
            pob_ocupada   = sum(PONDERA[ESTADO == 1]),
            pob_desocupada = sum(PONDERA[ESTADO == 2]),
            pob_inactiva  = sum(PONDERA[ESTADO == 3]),
            .by = c(ANO4, TRIMESTRE))

write_parquet(df_tasas, path_parquet_tasas)
cat(glue("Regenerado {path_parquet_tasas}"), "\n")


### -----------------------------------------------------------------------
### 5. Regenerar histórico de los 4 paneles del dashboard.
###    Solo agregamos paneles nuevos (incremental) usando la fn
###    regenerar_panel_historico() definida en 99-functions.R.
###
### Paneles regenerados:
###   - panel_cond_act_historico.csv          (epic #6 Fase 1)
###   - panel_cat_ocup_historico.csv          (epic #6 Fase 3)
###   - panel_formalidad_historico.csv        (epic #6 Fase 4)
###   - panel_formalidad_ampliada_historico.csv  (#15, solo 2023-T4+)
### -----------------------------------------------------------------------

### Las vars derivadas (formalidad, formalidad_ampliada) se agregan al
### microdato antes de regenerar los paneles que las usan.
df_eph_full <- df_eph_full |> agrega_vars_derivadas()

cat("\nRegenerando paneles históricos:\n\n")

regenerar_panel_historico(
  path_csv = path_panel_hist,  # panel_cond_act_historico.csv
  df_microdato = df_eph_full,
  var = "ESTADO",
  etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
  categorias = c("Ocupado", "Desocupado", "Inactivo")
)

regenerar_panel_historico(
  path_csv = "data_output/panel_cat_ocup_historico.csv",
  df_microdato = df_eph_full,
  var = "CAT_OCUP",
  etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),
  categorias = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),
  vars_extra = "CAT_OCUP"
)

regenerar_panel_historico(
  path_csv = "data_output/panel_formalidad_historico.csv",
  df_microdato = df_eph_full,
  var = "formalidad",
  etiquetas = c("Formal", "Informal"),
  categorias = c("Formal", "Informal"),
  vars_extra = c("CAT_OCUP", "PP07H", "formalidad")
)

regenerar_panel_historico(
  path_csv = "data_output/panel_formalidad_ampliada_historico.csv",
  df_microdato = df_eph_full,
  var = "formalidad_ampliada",
  etiquetas = c("Formal", "Informal"),
  categorias = c("Formal", "Informal"),
  vars_extra = c("CAT_OCUP", "PP07H", "PP05I", "PP05K", "formalidad_ampliada"),
  desde_panel = "2023-T4"
)

### Histórico de calidad del panel: % de personas-panel encontradas vs
### total de la muestra t0, por dúo trimestral (issue #36).
regenerar_calidad_panel(
  path_csv     = "data_output/calidad_panel_pct_historico.csv",
  df_microdato = df_eph_full
)


### -----------------------------------------------------------------------
### 6. Escribir lista de períodos nuevos para CI
### -----------------------------------------------------------------------

writeLines(
  descargas |>
    mutate(p = glue("{ANO4}-T{TRIMESTRE}")) |>
    pull(p),
  path_new_periods
)

cat("\nActualización completa.\n")
quit(status = 0)
