
source("ETL/00-libraries.R")

### Variables del microdato que usa la app.
### Las 9 originales soportan el análisis de Condición de actividad.
### CAT_OCUP, PP07H/J/K se sumaron para los análisis de Categoría ocupacional
### y Formal/Informal clásica (Fases 3-4 del epic #6).
### PP05I y PP05K se sumaron en #15: aportes jubilatorios propios y emisión
### de facturas, necesarios para la definición ampliada de informalidad
### (cuenta propia y patrones, EPH 2023+). Estas dos vars no existen en
### trimestres pre-2023; quedan NA para esos períodos.
vars_eph <- c("CODUSU", "NRO_HOGAR", "COMPONENTE", "ANO4", "TRIMESTRE",
              "CH04", "CH06", "ESTADO", "PONDERA",
              "CAT_OCUP", "PP07H", "PP07J", "PP07K",
              "PP05I", "PP05K")

### Carga única del microdato como Arrow Table (columnar comprimido).
### Mantener el dataset como Arrow en memoria reduce el footprint de
### ~570 MB (tibble en R) a ~50-80 MB. Los filtros y selecciones de
### los módulos operan via dplyr lazy sobre Arrow y `armo_base_panel()`
### hace collect() después de filtrar el subset chico que necesita
### (2 trimestres, ~10k filas), evitando OOM en shinyapps.io free tier.
###
### La lógica de vars derivadas (formalidad clásica + ampliada) está
### centralizada en agrega_vars_derivadas() (99-functions.R) y soporta
### tanto tibbles como Arrow Tables porque usa dplyr verbs.
df_eph_full <- arrow::read_parquet("data_raw/df_eph.parquet",
                                   as_data_frame = FALSE) |>
  dplyr::select(dplyr::all_of(vars_eph)) |>
  agrega_vars_derivadas()

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

### Rango de períodos disponibles (insumo para los selectInput dinámicos).
### Se exponen como variables globales para usarse en 02-transform.R y app.R.
### collect() materializa el subset chico (~80 filas) a tibble porque más
### abajo se accede vía $ANO4 que no funciona sobre Arrow Table.
periodos_disponibles <- df_eph_full |>
  dplyr::distinct(ANO4, TRIMESTRE) |>
  dplyr::arrange(ANO4, TRIMESTRE) |>
  dplyr::collect()

anios_disponibles <- sort(unique(periodos_disponibles$ANO4))
anio_max_disponible <- max(anios_disponibles)
