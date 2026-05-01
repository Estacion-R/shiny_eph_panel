### Agrega al microdato las variables derivadas que necesitan los análisis
### de Formal/Informal. Centraliza la lógica para que tanto 01-extract.R
### (carga inicial) como 03-update_data.R (regeneración de paneles) usen
### la misma definición.
###
### Vars agregadas:
###   - formalidad: definición clásica EPH (asalariados con PP07H).
###   - formalidad_ampliada: OIT 2023 (todos los ocupados con PP07H/PP05I/K).
###
### Defensivo: si alguna columna requerida no existe en el df, completamos
### con NA para que el mutate no rompa.
agrega_vars_derivadas <- function(df) {
  vars_requeridas <- c("CAT_OCUP", "PP07H", "PP05I", "PP05K")
  faltantes <- setdiff(vars_requeridas, names(df))
  for (col in faltantes) df[[col]] <- NA_integer_

  df |>
    dplyr::mutate(formalidad = dplyr::case_when(
      CAT_OCUP == 3 & PP07H == 1 ~ 1L,
      CAT_OCUP == 3 & PP07H == 2 ~ 2L,
      TRUE                       ~ NA_integer_
    )) |>
    dplyr::mutate(formalidad_ampliada = dplyr::case_when(
      CAT_OCUP == 3 & PP07H == 1                          ~ 1L,
      CAT_OCUP == 3 & PP07H == 2                          ~ 2L,
      CAT_OCUP %in% c(1L, 2L) & (PP05I == 1 | PP05K == 1) ~ 1L,
      CAT_OCUP %in% c(1L, 2L) & PP05I == 2 & PP05K == 2   ~ 2L,
      CAT_OCUP == 4                                       ~ 2L,
      TRUE                                                ~ NA_integer_
    ))
}


### Regenera incrementalmente un CSV histórico de panel para un análisis
### dado. Replica el patrón usado por panel_cond_act_historico.csv pero
### parametrizado por la variable a panelizar.
###
### @param path_csv path al CSV histórico (lee y reescribe).
### @param df_microdato microdato (df_eph_full) con vars derivadas si hace
###   falta. Idealmente ya pasado por agrega_vars_derivadas().
### @param var nombre de la columna a panelizar (ej: "ESTADO", "CAT_OCUP").
### @param etiquetas vector char con las labels para los códigos 1..N.
### @param categorias vector char con las categorías para armo_tabla_sankey
###   (suelen coincidir con etiquetas).
### @param vars_extra vars adicionales del microdato que necesita el panel
###   (ej: c("CAT_OCUP") cuando var = "CAT_OCUP").
### @param desde_panel string "YYYY-TN" optional: si se pasa, solo regenera
###   paneles cuyo trimestre inicial sea >= ese valor (útil para
###   formalidad_ampliada que solo aplica a 2023-T4+).
regenerar_panel_historico <- function(path_csv, df_microdato,
                                      var, etiquetas, categorias,
                                      vars_extra = character(),
                                      desde_panel = NULL) {

  panel_existente <- if (file.exists(path_csv)) {
    readr::read_csv(path_csv, show_col_types = FALSE)
  } else {
    tibble::tibble()
  }

  periodos_existentes <- if (nrow(panel_existente) > 0) {
    unique(panel_existente$periodo)
  } else {
    character(0)
  }

  paneles_posibles <- df_microdato |>
    dplyr::distinct(ANO4, TRIMESTRE) |>
    dplyr::arrange(ANO4, TRIMESTRE) |>
    dplyr::mutate(
      anio_post  = dplyr::if_else(TRIMESTRE %in% 1:3, ANO4, ANO4 + 1L),
      trim_post  = dplyr::if_else(TRIMESTRE %in% 1:3, TRIMESTRE + 1L, 1L),
      tiene_post = paste(anio_post, trim_post) %in%
        paste(df_microdato$ANO4, df_microdato$TRIMESTRE)
    ) |>
    dplyr::filter(tiene_post) |>
    dplyr::mutate(periodo = glue::glue("{ANO4}_t{TRIMESTRE}-t{trim_post}"))

  ### Filtro de período mínimo (ej: formalidad_ampliada solo desde 2023-T4)
  if (!is.null(desde_panel)) {
    desde_anio <- as.integer(stringr::str_extract(desde_panel, "^[0-9]{4}"))
    desde_trim <- as.integer(stringr::str_match(desde_panel, "[Tt]([0-9])$")[, 2])
    paneles_posibles <- paneles_posibles |>
      dplyr::filter(ANO4 > desde_anio |
                      (ANO4 == desde_anio & TRIMESTRE >= desde_trim))
  }

  paneles_a_calcular <- paneles_posibles |>
    dplyr::filter(!periodo %in% periodos_existentes)

  if (nrow(paneles_a_calcular) == 0) {
    cat(glue::glue("  [{basename(path_csv)}] sin paneles nuevos.\n\n"))
    return(invisible(panel_existente))
  }

  cat(glue::glue("  [{basename(path_csv)}] computando {nrow(paneles_a_calcular)} panel(es) nuevo(s)...\n"))

  vars_panel <- unique(c("ESTADO", "PONDERA", var, vars_extra))

  paneles_nuevos <- paneles_a_calcular |>
    purrr::pmap_dfr(function(ANO4, TRIMESTRE, anio_post, trim_post, periodo, ...) {
      df_panel <- armo_base_panel(
        anio_0 = ANO4, trimestre_0 = TRIMESTRE,
        anio_1 = anio_post, trimestre_1 = trim_post,
        df = df_microdato,
        variables = vars_panel
      )

      df_prep <- preparo_base(
        df = df_panel,
        periodo_base = "t_anterior",
        var = var,
        etiquetas = etiquetas
      )

      purrr::map_dfr(categorias, function(cat) {
        tryCatch({
          armo_tabla_sankey(table = df_prep, categoria = cat) |>
            dplyr::mutate(periodo = as.character(periodo))
        }, error = function(e) tibble::tibble())
      })
    })

  panel_actualizado <- dplyr::bind_rows(panel_existente, paneles_nuevos) |>
    dplyr::filter(from != "from")  # cleanup defensivo

  readr::write_csv(panel_actualizado, path_csv)
  cat(glue::glue("  [{basename(path_csv)}] OK ({nrow(panel_actualizado)} filas)\n\n"))

  invisible(panel_actualizado)
}


### Pre-computa el histórico de tasas (Persistencia / Salida / Entrada)
### para todos los paneles disponibles y todas las categorías. Output:
### tibble con cols (periodo, categoria, persistencia, salida, entrada).
###
### Reusa arma_tasas_destacadas() de R/utils_analisis.R por categoría y
### período. Issue #22.
build_tasas_historico <- function(df_microdato, var, etiquetas,
                                  vars_extra = character(),
                                  desde_panel = NULL) {

  ### Necesitamos arma_tasas_destacadas (en R/utils_analisis.R). El script
  ### que llama a esta fn debe haber hecho source antes.
  stopifnot(exists("arma_tasas_destacadas"))

  paneles <- df_microdato |>
    dplyr::distinct(ANO4, TRIMESTRE) |>
    dplyr::arrange(ANO4, TRIMESTRE) |>
    dplyr::mutate(
      anio_post  = dplyr::if_else(TRIMESTRE %in% 1:3, ANO4, ANO4 + 1L),
      trim_post  = dplyr::if_else(TRIMESTRE %in% 1:3, TRIMESTRE + 1L, 1L),
      tiene_post = paste(anio_post, trim_post) %in%
        paste(df_microdato$ANO4, df_microdato$TRIMESTRE)
    ) |>
    dplyr::filter(tiene_post) |>
    dplyr::mutate(periodo = glue::glue("{ANO4}_t{TRIMESTRE}-t{trim_post}"))

  if (!is.null(desde_panel)) {
    desde_anio <- as.integer(stringr::str_extract(desde_panel, "^[0-9]{4}"))
    desde_trim <- as.integer(stringr::str_match(desde_panel, "[Tt]([0-9])$")[, 2])
    paneles <- paneles |>
      dplyr::filter(ANO4 > desde_anio |
                      (ANO4 == desde_anio & TRIMESTRE >= desde_trim))
  }

  vars_panel <- unique(c("ESTADO", "PONDERA", var, vars_extra))

  paneles |>
    purrr::pmap_dfr(function(ANO4, TRIMESTRE, anio_post, trim_post, periodo, ...) {
      df_panel <- armo_base_panel(
        anio_0 = ANO4, trimestre_0 = TRIMESTRE,
        anio_1 = anio_post, trimestre_1 = trim_post,
        df = df_microdato,
        variables = vars_panel
      )

      purrr::map_dfr(etiquetas, function(cat) {
        tryCatch({
          tasas <- arma_tasas_destacadas(df_panel, var, etiquetas, cat)
          tibble::tibble(
            periodo = as.character(periodo),
            categoria = cat,
            persistencia = tasas$persistencia,
            salida = tasas$salida,
            entrada = tasas$entrada
          )
        }, error = function(e) tibble::tibble())
      })
    })
}


### Devuelve los duos trimestrales válidos para un año dado, evaluando contra
### los períodos efectivamente disponibles en `periodos_disponibles` (data
### frame con columnas ANO4 y TRIMESTRE). Un duo es válido cuando ambos
### extremos del panel existen en la base. El duo "4-1" cruza años: requiere
### (anio, T4) y (anio + 1, T1). Devuelve un named vector apto para usarse
### como `choices` de selectInput, manteniendo el orden trimestral.
duos_disponibles_por_anio <- function(anio, periodos_disponibles) {
  anio <- as.integer(anio)
  periodos_set <- paste(periodos_disponibles$ANO4, periodos_disponibles$TRIMESTRE)

  duos <- tibble::tibble(
    label  = c("1-2", "2-3", "3-4", "4-1"),
    value  = c(1L, 2L, 3L, 4L),
    inicio = paste(anio, c(1L, 2L, 3L, 4L)),
    fin    = paste(c(anio, anio, anio, anio + 1L), c(2L, 3L, 4L, 1L))
  ) |>
    dplyr::filter(inicio %in% periodos_set & fin %in% periodos_set)

  setNames(duos$value, duos$label)
}


### Arma la base de panel con los pares (t0, t1) de los entrevistados que
### aparecen en ambos trimestres consecutivos. Por default panteliza ESTADO
### + PONDERA (Condición de actividad). El parámetro `variables` permite
### incluir más columnas para análisis adicionales (CAT_OCUP, formalidad, etc.).
armo_base_panel <- function(anio_0, trimestre_0, anio_1 = NULL, trimestre_1 = NULL,
                            df = NULL,
                            variables = NULL){

  ### Modo runtime (default): usa el panel pre-computado en
  ### data_output/panel_runtime.parquet (cargado en 01-extract.R como
  ### df_panel_runtime). Solo filtra por (anio_0, trim_0) y devuelve
  ### el panel ya armado. Footprint mínimo en RAM, ideal para shinyapps.io.
  ###
  ### Modo legacy (cuando se pasa `df`): mantiene la lógica original con
  ### el microdato + organize_panels(). Lo usan los scripts ETL batch
  ### (05-build, 07-build, 08-build) que regeneran los CSV históricos.
  if (is.null(df)) {
    if (!exists("df_panel_runtime", envir = .GlobalEnv)) {
      stop("df_panel_runtime no disponible. Ejecutar ETL/01-extract.R o ",
           "pasar `df` explícito (microdato).")
    }
    return(
      get("df_panel_runtime", envir = .GlobalEnv) |>
        dplyr::filter(anio_0 == !!anio_0, trim_0 == !!trimestre_0) |>
        dplyr::select(-anio_0, -trim_0) |>
        dplyr::collect()
    )
  }

  ### Modo legacy: filtra el microdato y arma el panel via organize_panels().
  if (is.null(variables)) variables <- c("ESTADO", "PONDERA")
  list_eph_panel <- list(
    df |> filter(ANO4 == anio_0 & TRIMESTRE == trimestre_0) |> dplyr::collect(),
    df |> filter(ANO4 == anio_1 & TRIMESTRE == trimestre_1) |> dplyr::collect())

  organize_panels(bases = list_eph_panel,
                  variables = variables,
                  window = "trimestral")
}


### Agrega el panel resumiendo por (categoria_t0, categoria_t1) y calculando
### el porcentaje sobre el período base elegido. Output: tibble (from, to,
### weight=porc_base, id, periodo_base).
###
### Parámetros:
###   - var: columna del panel a resumir (default "ESTADO" para Condición
###     de actividad; usar "CAT_OCUP" para Categoría ocupacional, etc.).
###   - etiquetas: vector char donde el i-ésimo elemento es la etiqueta
###     del código i (default = etiquetas de ESTADO, indexadas en 1..4).
###     Para CAT_OCUP: c("Patron", "Cuenta_propia", "Asalariado", "TFSR").
preparo_base <- function(df,
                         periodo_base = "t_posterior",
                         var = "ESTADO",
                         etiquetas = c("Ocupado", "Desocupado", "Inactivo",
                                       "Trab_familiar")){

  assertthat::assert_that(periodo_base %in% c("t_anterior", "t_posterior"),
                          msg = "Las opciones válidas son 't_posterior' o 't_anterior'")

  var_t1 <- paste0(var, "_t1")

  ### Renombrar var/var_t1 a ESTADO/ESTADO_t1 para que el resto del código
  ### siga siendo legible. ESTADO acá es solo un alias interno.
  tabla <- df |>
    select(dplyr::all_of(c(var, var_t1, "PONDERA", "PONDERA_t1"))) |>
    rename(ESTADO    = !!rlang::sym(var),
           ESTADO_t1 = !!rlang::sym(var_t1))

  ### Mapeo código → etiqueta_tant / etiqueta_tpost. Solo aplica a códigos
  ### dentro del rango definido en `etiquetas`; otros valores quedan NA y se
  ### filtran al sumar.
  codigos <- seq_along(etiquetas)
  recode_t0 <- setNames(paste0(etiquetas, "_tant"), as.character(codigos))
  recode_t1 <- setNames(paste0(etiquetas, "_tpost"), as.character(codigos))

  tabla <- tabla |>
    mutate(ESTADO    = unname(recode_t0[as.character(ESTADO)]),
           ESTADO_t1 = unname(recode_t1[as.character(ESTADO_t1)])) |>
    filter(!is.na(ESTADO) & !is.na(ESTADO_t1))

  if(periodo_base == "t_anterior"){
    tabla <- tabla |>
      summarise(casos = sum(PONDERA),
                .by = c("ESTADO", "ESTADO_t1")) |>
      group_by(ESTADO) |>
      mutate(porc_base = round(casos / sum(casos) * 100, 1),
             periodo_base = "t_anterior",
             id = paste(ESTADO, ESTADO_t1, sep = " - ")) |> ungroup() |>
      select(ESTADO, ESTADO_t1, porc_base, id, periodo_base)
  }

  if(periodo_base == "t_posterior"){
    tabla <- tabla |>
      summarise(casos = sum(PONDERA_t1),
                .by = c("ESTADO_t1", "ESTADO")) |>
      group_by(ESTADO_t1) |>
      mutate(porc_base = round(casos / sum(casos) * 100, 1),
             periodo_base = "t_posterior",
             id = paste(ESTADO, ESTADO_t1, sep = " - ")) |> ungroup() |>
      select(ESTADO, ESTADO_t1, porc_base, id, periodo_base)
  }

  return(tabla)
}

### Test
#test <- preparo_base(df = df_eph_panel, periodo_base = "t_anterior")

armo_tabla_sankey <- function(table, categoria){
  
  if(unique(table$periodo_base) == "t_anterior"){
    periodo <- "tant"}
  
  if(unique(table$periodo_base) == "t_posterior"){
    periodo <- "tpost"
  }
  
  names(table) <- c("from", "to", "weight", "id", "periodo_base")

  if(unique(table$periodo_base) == "t_anterior"){
    tabla_sankey <- table |>
      filter(from == glue::glue("{stringr::str_to_sentence(categoria)}_{periodo}")) |> 
      mutate(categoria = categoria)
  }
  
  if(unique(table$periodo_base) == "t_posterior"){
    tabla_sankey <- table |>
      filter(to == glue::glue("{stringr::str_to_sentence(categoria)}_{periodo}")) |> 
      mutate(categoria = categoria)
  }
  
  tabla_sankey <- tabla_sankey |> 
    mutate(
      across(c("from", "to", "id"), \(x) stringr::str_replace_all(x, "_tant", "_t0")),
      across(c("from", "to", "id"), \(x) stringr::str_replace_all(x, "_tpost", "_t1")))
        # from = stringr::str_replace_all(from, "_tant", "_t0"),
        #    to   = stringr::str_replace_all(to, "_tpost", "_t1"))
  
  return(tabla_sankey)
}

# 
# armo_sankey <- function(table){
#   
#   if(unique(table$periodo_base) == "t_anterior"){
#     periodo <- "tant"}
#   
#   if(unique(table$periodo_base) == "t_posterior"){
#     periodo <- "tpost"
#   }
#   
#   names(table) <- c("from", "to", "weight", "id", "periodo_base", "categoria")
#   
#   highcharter::hchart(table, "sankey", 
#          name = "Gender based Outcomes") |> 
#     highcharter::hc_title(text= glue::glue(
#       "Población base: {unique(table$categoria)} - {ifelse(periodo == 'tant', 'Trimestre anterior', 'Trimestre posterior')}"))
#     #hc_subtitle(text= "Población ocupada al trimestre 2 de 2023")
# 
# }


### Regenera incrementalmente el histórico de calidad del panel: para cada
### dúo trimestral (t0 → t1) calcula cuántas personas de la muestra t0
### aparecen también en t1 (panel matched), tanto en filas como ponderado.
###
### Replica el patrón idempotente de regenerar_panel_historico(): si el
### CSV existe, agrega solo dúos faltantes; si no, lo crea completo.
###
### @param path_csv ruta al CSV histórico (ej "data_output/calidad_panel_pct_historico.csv")
### @param df_microdato tibble con el microdato (necesita ANO4, TRIMESTRE,
###   ESTADO, PONDERA, CODUSU, NRO_HOGAR, COMPONENTE).
###
### Schema del CSV:
###   periodo, anio_0, trim_0, anio_1, trim_1,
###   n_t0, pondera_t0, n_panel, pondera_panel,
###   pct_encontrado_n, pct_encontrado_pondera
regenerar_calidad_panel <- function(path_csv, df_microdato) {

  hist_existente <- if (file.exists(path_csv)) {
    readr::read_csv(path_csv, show_col_types = FALSE)
  } else {
    tibble::tibble(periodo = character())
  }

  periodos_existentes <- if (nrow(hist_existente) > 0) {
    unique(hist_existente$periodo)
  } else {
    character(0)
  }

  ### Mismo cómputo de dúos válidos que regenerar_panel_historico().
  duos_posibles <- df_microdato |>
    dplyr::distinct(ANO4, TRIMESTRE) |>
    dplyr::arrange(ANO4, TRIMESTRE) |>
    dplyr::mutate(
      anio_post  = dplyr::if_else(TRIMESTRE %in% 1:3, ANO4, ANO4 + 1L),
      trim_post  = dplyr::if_else(TRIMESTRE %in% 1:3, TRIMESTRE + 1L, 1L),
      tiene_post = paste(anio_post, trim_post) %in%
        paste(df_microdato$ANO4, df_microdato$TRIMESTRE)
    ) |>
    dplyr::filter(tiene_post) |>
    dplyr::mutate(periodo = glue::glue("{ANO4}_t{TRIMESTRE}-t{trim_post}"))

  duos_a_calcular <- duos_posibles |>
    dplyr::filter(!periodo %in% periodos_existentes)

  if (nrow(duos_a_calcular) == 0) {
    cat(glue::glue("  [{basename(path_csv)}] sin dúos nuevos.\n\n"))
    return(invisible(hist_existente))
  }

  cat(glue::glue("  [{basename(path_csv)}] computando {nrow(duos_a_calcular)} dúo(s) nuevo(s)...\n"))

  filas_nuevas <- duos_a_calcular |>
    purrr::pmap(function(ANO4, TRIMESTRE, anio_post, trim_post, periodo, ...) {
      base_t0 <- df_microdato |>
        dplyr::filter(ANO4 == .env$ANO4, TRIMESTRE == .env$TRIMESTRE,
                      ESTADO %in% 1:4)

      ### Variables CH04 (sexo) y CH06 (edad) para detectar inconsistencias
      ### entre t0 y t1 (issue #37). El campo `consistencia` que devuelve
      ### eph::organize_panels() ya marca el flag general; con CH04/CH06
      ### desglosamos por tipo de inconsistencia.
      panel <- armo_base_panel(
        anio_0      = ANO4, trimestre_0 = TRIMESTRE,
        anio_1      = anio_post, trimestre_1 = trim_post,
        df          = df_microdato,
        variables   = c("ESTADO", "PONDERA", "CH04", "CH06")
      ) |>
        dplyr::filter(ESTADO %in% 1:4)

      ### Detección de inconsistencias específicas:
      ###   - sexo:  CH04 t0 ≠ CH04 t1 (debe ser invariante).
      ###   - edad:  CH06_t1 fuera del rango [CH06, CH06 + 1] (en un panel
      ###            de 1 trimestre, la edad sube como mucho 1 año).
      ### Una persona puede tener ambas inconsistencias a la vez; la
      ### "total" es el flag de eph::organize_panels (más amplio: incluye
      ### otras cosas como saltos en NIVEL_ED si estuvieran).
      panel_inc <- panel |>
        dplyr::mutate(
          inc_sexo = !is.na(CH04) & !is.na(CH04_t1) & CH04 != CH04_t1,
          inc_edad = !is.na(CH06) & !is.na(CH06_t1) &
                     (CH06_t1 < CH06 | CH06_t1 > CH06 + 1L),
          inc_total = !consistencia
        )

      sum_w <- function(w, mask) sum(w[mask], na.rm = TRUE)

      tibble::tibble(
        periodo                = as.character(periodo),
        anio_0                 = ANO4,
        trim_0                 = TRIMESTRE,
        anio_1                 = anio_post,
        trim_1                 = trim_post,
        n_t0                   = nrow(base_t0),
        pondera_t0             = sum(base_t0$PONDERA, na.rm = TRUE),
        n_panel                = nrow(panel),
        pondera_panel          = sum(panel$PONDERA, na.rm = TRUE),
        n_inc_total            = sum(panel_inc$inc_total, na.rm = TRUE),
        n_inc_sexo             = sum(panel_inc$inc_sexo, na.rm = TRUE),
        n_inc_edad             = sum(panel_inc$inc_edad, na.rm = TRUE),
        pondera_inc_total      = sum_w(panel_inc$PONDERA, panel_inc$inc_total),
        pondera_inc_sexo       = sum_w(panel_inc$PONDERA, panel_inc$inc_sexo),
        pondera_inc_edad       = sum_w(panel_inc$PONDERA, panel_inc$inc_edad)
      )
    }) |>
    purrr::list_rbind() |>
    dplyr::mutate(
      pct_encontrado_n       = round(n_panel / n_t0 * 100, 2),
      pct_encontrado_pondera = round(pondera_panel / pondera_t0 * 100, 2),
      ### Inconsistencias como % sobre el panel encontrado (no sobre t0).
      ### La pregunta es: de los matched, cuántos vienen con problemas.
      pct_inc_total          = round(n_inc_total / n_panel * 100, 2),
      pct_inc_sexo           = round(n_inc_sexo  / n_panel * 100, 2),
      pct_inc_edad           = round(n_inc_edad  / n_panel * 100, 2)
    )

  hist_actualizado <- dplyr::bind_rows(hist_existente, filas_nuevas) |>
    dplyr::arrange(anio_0, trim_0)

  readr::write_csv(hist_actualizado, path_csv)
  cat(glue::glue("  [{basename(path_csv)}] OK ({nrow(hist_actualizado)} filas)\n\n"))

  invisible(hist_actualizado)
}


### Notas para highcharter
df_to_annotations_labels <- function(df, xAxis = 0, yAxis = 0) {
  
  stopifnot(hasName(df, "x"))
  stopifnot(hasName(df, "y"))
  stopifnot(hasName(df, "text"))
  
  df %>% 
    rowwise() %>% 
    mutate(point = list(list(x = x, y = y, xAxis = 0, yAxis = 0))) %>% 
    select(-x, -y)  
  
}
