
source("ETL/00-libraries.R")

### --- Estrategia de carga de datos para runtime ----------------------------
###
### Antes (hasta 2026-04-30): cargábamos df_eph_full (microdato 740k filas)
### como Arrow Table y armo_base_panel() filtraba + organize_panels() en
### cada cálculo. Esto sumaba ~570 MB de RAM (tibble) y rompía el plan
### free de shinyapps.io con OOM.
###
### Ahora: pre-computamos los paneles armados (output de armo_base_panel)
### para todos los dúos válidos en ETL/09-build_paneles_runtime.R y los
### guardamos en data_output/panel_runtime.parquet (~21 MB en disco). En
### runtime sólo cargamos ese parquet como Arrow Table y armo_base_panel
### filtra por (anio_0, trim_0) → collect(). Footprint mucho menor y la
### lógica de los módulos no cambia.

### Panel runtime pre-computado: superset de variables que necesitan los
### 3 análisis (cond_act, cat_ocup, formalidad). Cols clave: anio_0,
### trim_0 para filtrar el dúo + las cols del panel armado (CODUSU,
### ESTADO, ESTADO_t1, CAT_OCUP, CAT_OCUP_t1, formalidad, formalidad_t1,
### formalidad_ampliada, formalidad_ampliada_t1, PONDERA, PONDERA_t1, ...).
### Ver ETL/09-build_paneles_runtime.R para el script generador.
df_panel_runtime <- arrow::read_parquet("data_output/panel_runtime.parquet",
                                        as_data_frame = FALSE)

### Panel runtime ANUAL (issue #44): mismo schema, distinto contenido.
### Parea cada vivienda con el MISMO trimestre del año siguiente
### (T1 año X ↔ T1 año X+1) en lugar de trimestres consecutivos.
###
### IMPORTANTE: NO se carga al boot (hotfix v0.7.2 OOM). Mantener
### dos arrow Tables abiertas simultáneamente (intertrim + anual)
### supera el budget de RAM del free tier de shinyapps.io. En su lugar,
### guardamos solo el path; armo_base_panel(window = "anual") abre el
### parquet on-demand y lo cierra después de filtrar.
PATH_PANEL_RUNTIME_ANUAL <- "data_output/panel_runtime_anual.parquet"

### Histórico pre-computado por data_generator.R
df_cond_act <- arrow::read_csv_arrow("data_output/panel_cond_act_historico.csv")

### Histórico pre-computado por ETL/05-build_panel_cat_ocup.R
### Movilidad entre Categorías ocupacionales (CAT_OCUP=1..4) dentro de la
### población Ocupada. Mismo schema que df_cond_act.
df_cat_ocup <- arrow::read_csv_arrow("data_output/panel_cat_ocup_historico.csv")

### Histórico pre-computado por ETL/06-build_panel_formalidad.R
### Movilidad entre asalariados Formales e Informales (PP07H) sobre el
### universo de asalariados (CAT_OCUP=3). Mismo schema que df_cond_act.
### Definición CLÁSICA (serie 2003+).
df_formalidad <- arrow::read_csv_arrow("data_output/panel_formalidad_historico.csv")

### Histórico pre-computado por ETL/07-build_panel_formalidad_ampliada.R
### Definición AMPLIADA (OIT 2023). Universo: ocupados completo. Solo
### desde 4T 2023 porque depende de PP05I/K. Issue #15.
### Carga condicional: si el script no se corrió aún, queda como tibble
### vacía y el toggle del módulo muestra mensaje informativo.
path_amp <- "data_output/panel_formalidad_ampliada_historico.csv"
df_formalidad_ampliada <- if (file.exists(path_amp)) {
  arrow::read_csv_arrow(path_amp)
} else {
  tibble::tibble(from = character(), to = character(), weight = numeric(),
                 id = character(), categoria = character(), periodo = character())
}
rm(path_amp)

### Versiones ANUALES de los paneles agregados (issue #46).
### Generadas por ETL/11-build_historicos_anuales.R. Carga condicional
### con tibble vacía como fallback.
cargar_panel_csv <- function(path) {
  if (file.exists(path)) {
    arrow::read_csv_arrow(path)
  } else {
    tibble::tibble(from = character(), to = character(), weight = numeric(),
                   id = character(), categoria = character(),
                   periodo = character())
  }
}
df_cond_act_anual          <- cargar_panel_csv("data_output/panel_cond_act_anual_historico.csv")
df_cat_ocup_anual          <- cargar_panel_csv("data_output/panel_cat_ocup_anual_historico.csv")
df_formalidad_anual        <- cargar_panel_csv("data_output/panel_formalidad_anual_historico.csv")
df_formalidad_ampliada_anual <- cargar_panel_csv("data_output/panel_formalidad_ampliada_anual_historico.csv")

### Tasas del mercado de trabajo (totales por trimestre)
df_tasas_mt <- arrow::read_parquet("data_output/df_tasas_mt.parquet")

### Históricos de tasas (Persistencia / Salida / Entrada) por análisis.
### Pre-computados por ETL/08-build_tasas_historico.R (issue #22).
### Schema: (periodo, categoria, persistencia, salida, entrada).
### Carga condicional: si el script no se corrió, queda tibble vacía y el
### sub-tab Tasas muestra mensaje informativo.
cargar_tasas_csv <- function(path) {
  if (file.exists(path)) {
    arrow::read_csv_arrow(path)
  } else {
    tibble::tibble(periodo = character(), categoria = character(),
                   persistencia = double(), salida = double(),
                   entrada = double())
  }
}
df_tasas_cond_act        <- cargar_tasas_csv("data_output/tasas_cond_act_historico.csv")
df_tasas_cat_ocup        <- cargar_tasas_csv("data_output/tasas_cat_ocup_historico.csv")
df_tasas_formalidad      <- cargar_tasas_csv("data_output/tasas_formalidad_historico.csv")
df_tasas_formalidad_amp  <- cargar_tasas_csv("data_output/tasas_formalidad_ampliada_historico.csv")

### Versiones ANUALES de las tasas históricas (issue #46).
### Generadas por ETL/11-build_historicos_anuales.R. Mismo schema.
df_tasas_cond_act_anual        <- cargar_tasas_csv("data_output/tasas_cond_act_anual_historico.csv")
df_tasas_cat_ocup_anual        <- cargar_tasas_csv("data_output/tasas_cat_ocup_anual_historico.csv")
df_tasas_formalidad_anual      <- cargar_tasas_csv("data_output/tasas_formalidad_anual_historico.csv")
df_tasas_formalidad_amp_anual  <- cargar_tasas_csv("data_output/tasas_formalidad_ampliada_anual_historico.csv")

### Histórico de calidad del panel (issue #36). Pre-computado por
### ETL/10-build_calidad_panel.R y mantenido al día por 03-update_data.R.
### Schema: periodo, anio_0, trim_0, anio_1, trim_1, n_t0, pondera_t0,
### n_panel, pondera_panel, pct_encontrado_n, pct_encontrado_pondera.
path_calidad <- "data_output/calidad_panel_pct_historico.csv"
df_calidad_panel <- if (file.exists(path_calidad)) {
  arrow::read_csv_arrow(path_calidad) |>
    dplyr::collect() |>
    dplyr::arrange(anio_0, trim_0)
} else {
  tibble::tibble(periodo = character(), anio_0 = integer(), trim_0 = integer(),
                 anio_1 = integer(), trim_1 = integer(),
                 n_t0 = integer(), pondera_t0 = double(),
                 n_panel = integer(), pondera_panel = double(),
                 pct_encontrado_n = double(), pct_encontrado_pondera = double())
}
rm(path_calidad)

### Rango de períodos disponibles (insumo para los selectInput dinámicos).
### Se deriva del panel_runtime: cualquier (anio_0, trim_0) es un trimestre
### que existe como inicio de algún dúo, y los t1 también existen como t0
### de otro dúo (excepto el último). Hacemos union de ambos pares para
### cubrir todos los trimestres del microdato sin tener que cargarlo.
periodos_disponibles_t0 <- df_panel_runtime |>
  dplyr::distinct(anio_0, trim_0) |>
  dplyr::collect() |>
  dplyr::rename(ANO4 = anio_0, TRIMESTRE = trim_0)
periodos_disponibles_t1 <- df_panel_runtime |>
  dplyr::distinct(ANO4_t1, TRIMESTRE_t1) |>
  dplyr::collect() |>
  dplyr::rename(ANO4 = ANO4_t1, TRIMESTRE = TRIMESTRE_t1)
periodos_disponibles <- dplyr::bind_rows(periodos_disponibles_t0,
                                         periodos_disponibles_t1) |>
  dplyr::distinct() |>
  dplyr::arrange(ANO4, TRIMESTRE)
rm(periodos_disponibles_t0, periodos_disponibles_t1)

anios_disponibles <- sort(unique(periodos_disponibles$ANO4))
anio_max_disponible <- max(anios_disponibles)


### Análogos para el panel ANUAL (issue #44). Derivamos periodos
### disponibles abriendo el parquet TEMPORALMENTE para extraer las
### columnas anio_0/trim_0 + ANO4_t1/TRIMESTRE_t1, y lo cerramos.
### NO mantenemos la Arrow Table abierta en memoria (hotfix v0.7.2 OOM).
if (file.exists(PATH_PANEL_RUNTIME_ANUAL)) {
  ### open_dataset es lazy real (solo lee footer + row groups
  ### necesarios). Mucho más liviano que read_parquet (que carga
  ### todo el archivo a memoria). Hotfix v0.7.3 sobre OOM al
  ### togglear, mismo patrón que armo_base_panel(window = "anual").
  ds_anual_tmp <- arrow::open_dataset(PATH_PANEL_RUNTIME_ANUAL)
  periodos_anual_t0 <- ds_anual_tmp |>
    dplyr::select(anio_0, trim_0) |>
    dplyr::distinct() |>
    dplyr::collect() |>
    dplyr::rename(ANO4 = anio_0, TRIMESTRE = trim_0)
  periodos_anual_t1 <- ds_anual_tmp |>
    dplyr::select(ANO4_t1, TRIMESTRE_t1) |>
    dplyr::distinct() |>
    dplyr::collect() |>
    dplyr::rename(ANO4 = ANO4_t1, TRIMESTRE = TRIMESTRE_t1)
  ### periodos_disponibles_anual: union (t0+t1) para validar dúos en
  ### duos_disponibles_por_anio (chequea inicio/fin contra el set).
  periodos_disponibles_anual <- dplyr::bind_rows(periodos_anual_t0,
                                                 periodos_anual_t1) |>
    dplyr::distinct() |>
    dplyr::arrange(ANO4, TRIMESTRE)
  ### anios_disponibles_anual: SOLO los t0 (años base válidos para
  ### seleccionar). Si tomáramos la union, incluiríamos años que solo
  ### existen como t1 (ej. 2025 cuando 2026 todavía no llegó), y el
  ### usuario podría seleccionar 2025 como base sin que tenga dúo válido.
  anios_disponibles_anual <- sort(unique(periodos_anual_t0$ANO4))
  rm(periodos_anual_t0, periodos_anual_t1, ds_anual_tmp)
  invisible(gc(verbose = FALSE))
} else {
  periodos_disponibles_anual <- periodos_disponibles[0, ]
  anios_disponibles_anual <- integer(0)
}
