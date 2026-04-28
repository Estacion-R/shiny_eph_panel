
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

### Carga única del microdato en memoria + variables derivadas.
### La lógica de las vars derivadas (formalidad clásica + ampliada) está
### centralizada en agrega_vars_derivadas() (99-functions.R) para que el
### workflow mensual de update también las use.
df_eph_full <- arrow::read_parquet("data_raw/df_eph.parquet") |>
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

### Rango de períodos disponibles (insumo para los selectInput dinámicos).
### Se exponen como variables globales para usarse en 02-transform.R y app.R
periodos_disponibles <- df_eph_full |>
  dplyr::distinct(ANO4, TRIMESTRE) |>
  dplyr::arrange(ANO4, TRIMESTRE)

anios_disponibles <- sort(unique(periodos_disponibles$ANO4))
anio_max_disponible <- max(anios_disponibles)
