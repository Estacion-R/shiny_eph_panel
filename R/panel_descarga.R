### Diccionario canónico del panel_runtime (issue #35).
###
### Este archivo originalmente exponía la vista "Datos" (descarga del dataset
### completo). En F3 (#77, 2026-05-23) el Armador de panel (R/mod_armador.R)
### la reemplazó con descarga filtrada, y en el housekeeping de código muerto
### (#39) se eliminaron `panel_descarga_content`, `panel_descarga` y los
### helpers `download_*()` que ya no se montaban en ninguna vista.
###
### De aquel panel sólo sobrevive el tibble `columnas_panel_runtime`: el
### diccionario canónico de las 31 variables, que mod_armador referencia para
### su descarga de diccionario.


### Diccionario de las 31 columnas del panel_runtime. Se sirve como CSV
### descargable y también lo usamos para validar la cobertura del panel.
columnas_panel_runtime <- tibble::tribble(
  ~Variable,                ~Descripción,
  "anio_0",                 "Año del primer trimestre del dúo (t0).",
  "trim_0",                 "Trimestre del primer trimestre del dúo (t0).",
  "CODUSU",                 "ID de vivienda. Clave de pareo del panel junto con NRO_HOGAR y COMPONENTE.",
  "NRO_HOGAR",              "Número de hogar dentro de la vivienda.",
  "COMPONENTE",             "Número de persona dentro del hogar.",
  "ANO4",                   "Año del registro en t0.",
  "TRIMESTRE",              "Trimestre del registro en t0.",
  "CH04",                   "Sexo (1=Varón, 2=Mujer).",
  "CH06",                   "Edad en años cumplidos.",
  "AGLOMERADO",             "Aglomerado urbano EPH (código INDEC). Atributo fijo de la vivienda: no cambia entre t0 y t1, por eso no tiene versión _t1.",
  "ESTADO",                 "Condición de actividad en t0 (1=Ocupado, 2=Desocupado, 3=Inactivo, 4=Menor de 10 años).",
  "CAT_OCUP",               "Categoría ocupacional en t0 (1=Patrón, 2=Cuenta propia, 3=Asalariado, 4=Trab. familiar).",
  "PP07H",                  "Descuento jubilatorio (asalariados, t0). 1=Sí, 2=No.",
  "PP05I",                  "Monotributo cuenta propia en t0 (disponible desde 2023-T4).",
  "PP05K",                  "Aportes propios cuenta propia en t0 (disponible desde 2023-T4).",
  "formalidad",             "Formalidad clásica en t0 (1=Formal, 2=Informal, NA si no aplica). Definida solo para asalariados.",
  "formalidad_ampliada",    "Formalidad ampliada en t0 (todos los ocupados con info de aportes).",
  "PONDERA",                "Factor de expansión de la persona en t0.",
  "Periodo",                "Etiqueta del dúo trimestral. Formato 'YYYY_tA-tB'.",
  "ANO4_t1",                "Año del registro en t1 (segundo trimestre del dúo).",
  "TRIMESTRE_t1",           "Trimestre del registro en t1.",
  "CH04_t1",                "Sexo declarado en t1. Diferencia respecto a CH04 = inconsistencia.",
  "CH06_t1",                "Edad en t1. Diferencia esperada con CH06: 0 o +1 año.",
  "ESTADO_t1",              "Condición de actividad en t1.",
  "CAT_OCUP_t1",            "Categoría ocupacional en t1.",
  "PP07H_t1",               "Descuento jubilatorio en t1.",
  "PP05I_t1",               "Monotributo cuenta propia en t1.",
  "PP05K_t1",               "Aportes propios cuenta propia en t1.",
  "formalidad_t1",          "Formalidad clásica en t1.",
  "formalidad_ampliada_t1", "Formalidad ampliada en t1.",
  "PONDERA_t1",             "Factor de expansión de la persona en t1.",
  "consistencia",           "Flag de consistencia entre t0 y t1 (eph::organize_panels). FALSE = inconsistencia detectada (sexo distinto, edad imposible, etc.)."
)
