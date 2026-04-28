
source("ETL/00-libraries.R")

### Variables del microdato que usa la app.
### Las 9 originales soportan el análisis de Condición de actividad.
### CAT_OCUP, PP07H/J/K se suman para los análisis de Categoría ocupacional
### y Formal/Informal (Fases 3-4 del epic #6).
vars_eph <- c("CODUSU", "NRO_HOGAR", "COMPONENTE", "ANO4", "TRIMESTRE",
              "CH04", "CH06", "ESTADO", "PONDERA",
              "CAT_OCUP", "PP07H", "PP07J", "PP07K")

### Carga única del microdato en memoria.
### Antes se leía el parquet en cada llamada a armo_base_panel(), lo que
### generaba latencia perceptible al cambiar de filtros en la pestaña "Foto".
df_eph_full <- arrow::read_parquet("data_raw/df_eph.parquet") |>
  dplyr::select(dplyr::all_of(vars_eph)) |>
  ### Variable derivada para el análisis Formal/Informal (Fase 4 del epic #6).
  ### Definición clásica EPH (serie 2003+): solo asalariados (CAT_OCUP=3),
  ### formal si paga aportes jubilatorios (PP07H=1), informal si no (PP07H=2).
  ### El resto queda NA para que preparo_base() los filtre del panel.
  dplyr::mutate(formalidad = dplyr::case_when(
    CAT_OCUP == 3 & PP07H == 1 ~ 1L,
    CAT_OCUP == 3 & PP07H == 2 ~ 2L,
    TRUE                       ~ NA_integer_
  ))

### Histórico pre-computado por data_generator.R
df_cond_act <- arrow::read_csv_arrow("data_output/panel_cond_act_historico.csv")

### Histórico pre-computado por ETL/05-build_panel_cat_ocup.R
### Movilidad entre Categorías ocupacionales (CAT_OCUP=1..4) dentro de la
### población Ocupada. Mismo schema que df_cond_act.
df_cat_ocup <- arrow::read_csv_arrow("data_output/panel_cat_ocup_historico.csv")

### Histórico pre-computado por ETL/06-build_panel_formalidad.R
### Movilidad entre asalariados Formales e Informales (PP07H) sobre el
### universo de asalariados (CAT_OCUP=3). Mismo schema que df_cond_act.
df_formalidad <- arrow::read_csv_arrow("data_output/panel_formalidad_historico.csv")

### Tasas del mercado de trabajo (totales por trimestre)
df_tasas_mt <- arrow::read_parquet("data_output/df_tasas_mt.parquet")

### Rango de períodos disponibles (insumo para los selectInput dinámicos).
### Se exponen como variables globales para usarse en 02-transform.R y app.R
periodos_disponibles <- df_eph_full |>
  dplyr::distinct(ANO4, TRIMESTRE) |>
  dplyr::arrange(ANO4, TRIMESTRE)

anios_disponibles <- sort(unique(periodos_disponibles$ANO4))
anio_max_disponible <- max(anios_disponibles)
