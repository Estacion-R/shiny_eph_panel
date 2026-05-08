### Pre-cómputo de los CSVs históricos en modo ANUAL (issue #46).
###
### Espejo de la sección de regenerar_panel_historico + build_tasas_historico
### que vive en ETL/03-update_data.R, pero pasando window="anual" a las
### funciones. Genera los datasets que alimentan Película y Tasas en
### modo Interanual:
###
###   data_output/panel_cond_act_anual_historico.csv
###   data_output/panel_cat_ocup_anual_historico.csv
###   data_output/panel_formalidad_anual_historico.csv
###   data_output/panel_formalidad_ampliada_anual_historico.csv
###   data_output/tasas_cond_act_anual_historico.csv
###   data_output/tasas_cat_ocup_anual_historico.csv
###   data_output/tasas_formalidad_anual_historico.csv
###   data_output/tasas_formalidad_ampliada_anual_historico.csv
###
### Cuándo correr:
###   - Después del 03-update_data.R en el pipeline mensual (issue #48).
###   - Manualmente cuando se cambie la lógica de armo_base_panel o las
###     funciones regenerar_panel_historico / build_tasas_historico.

suppressPackageStartupMessages({
  source("ETL/00-libraries.R")
  source("ETL/99-functions.R")
  source("R/utils_analisis.R")  ### arma_tasas_destacadas
})

cat("=== Pre-computando históricos ANUALES (window = 'anual') ===\n")

### Cargar el microdato + sumar vars derivadas (formalidad, ampliada).
df_eph_full <- arrow::read_parquet("data_raw/df_eph.parquet") |>
  agrega_vars_derivadas()

cat("Microdato cargado:", nrow(df_eph_full), "filas\n\n")


### --------------------------------------------------------------------
### Paneles agregados (matrices de transición por categoría)
### --------------------------------------------------------------------

cat("--- Paneles agregados ---\n\n")

regenerar_panel_historico(
  path_csv = "data_output/panel_cond_act_anual_historico.csv",
  df_microdato = df_eph_full,
  var = "ESTADO",
  etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
  categorias = c("Ocupado", "Desocupado", "Inactivo"),
  window = "anual"
)

regenerar_panel_historico(
  path_csv = "data_output/panel_cat_ocup_anual_historico.csv",
  df_microdato = df_eph_full,
  var = "CAT_OCUP",
  etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),
  categorias = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),
  vars_extra = "CAT_OCUP",
  window = "anual"
)

regenerar_panel_historico(
  path_csv = "data_output/panel_formalidad_anual_historico.csv",
  df_microdato = df_eph_full,
  var = "formalidad",
  etiquetas = c("Formal", "Informal"),
  categorias = c("Formal", "Informal"),
  vars_extra = c("CAT_OCUP", "PP07H", "formalidad"),
  window = "anual"
)

regenerar_panel_historico(
  path_csv = "data_output/panel_formalidad_ampliada_anual_historico.csv",
  df_microdato = df_eph_full,
  var = "formalidad_ampliada",
  etiquetas = c("Formal", "Informal"),
  categorias = c("Formal", "Informal"),
  vars_extra = c("CAT_OCUP", "PP07H", "PP05I", "PP05K", "formalidad_ampliada"),
  desde_panel = "2023-T4",
  window = "anual"
)


### --------------------------------------------------------------------
### Tasas históricas (Persistencia / Salida / Entrada)
### --------------------------------------------------------------------

cat("--- Tasas históricas ---\n\n")

tasas_cond_act_anual <- build_tasas_historico(
  df_microdato = df_eph_full,
  var = "ESTADO",
  etiquetas = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),
  window = "anual"
)
readr::write_csv(tasas_cond_act_anual,
                 "data_output/tasas_cond_act_anual_historico.csv")
cat(glue::glue("  tasas_cond_act_anual_historico.csv OK ({nrow(tasas_cond_act_anual)} filas)\n\n"))

tasas_cat_ocup_anual <- build_tasas_historico(
  df_microdato = df_eph_full,
  var = "CAT_OCUP",
  etiquetas = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),
  vars_extra = "CAT_OCUP",
  window = "anual"
)
readr::write_csv(tasas_cat_ocup_anual,
                 "data_output/tasas_cat_ocup_anual_historico.csv")
cat(glue::glue("  tasas_cat_ocup_anual_historico.csv OK ({nrow(tasas_cat_ocup_anual)} filas)\n\n"))

tasas_formalidad_anual <- build_tasas_historico(
  df_microdato = df_eph_full,
  var = "formalidad",
  etiquetas = c("Formal", "Informal"),
  vars_extra = c("CAT_OCUP", "PP07H", "formalidad"),
  window = "anual"
)
readr::write_csv(tasas_formalidad_anual,
                 "data_output/tasas_formalidad_anual_historico.csv")
cat(glue::glue("  tasas_formalidad_anual_historico.csv OK ({nrow(tasas_formalidad_anual)} filas)\n\n"))

tasas_formalidad_amp_anual <- build_tasas_historico(
  df_microdato = df_eph_full,
  var = "formalidad_ampliada",
  etiquetas = c("Formal", "Informal"),
  vars_extra = c("CAT_OCUP", "PP07H", "PP05I", "PP05K", "formalidad_ampliada"),
  desde_panel = "2023-T4",
  window = "anual"
)
readr::write_csv(tasas_formalidad_amp_anual,
                 "data_output/tasas_formalidad_ampliada_anual_historico.csv")
cat(glue::glue("  tasas_formalidad_ampliada_anual_historico.csv OK ({nrow(tasas_formalidad_amp_anual)} filas)\n\n"))


### --------------------------------------------------------------------
### Calidad del panel (issue #47)
### --------------------------------------------------------------------

cat("--- Calidad del panel anual ---\n\n")

regenerar_calidad_panel(
  path_csv     = "data_output/calidad_panel_anual_pct_historico.csv",
  df_microdato = df_eph_full,
  window       = "anual"
)


cat("=== Pre-cómputo de históricos anuales completo ===\n")
