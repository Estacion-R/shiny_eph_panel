### Configuraciones de los análisis de panel para mod_analisis() genérico
### (issue #12).
###
### Cada config define todo lo que cambia entre análisis (variable a
### panelizar, choices de UI, etiquetas humanas, datasets históricos,
### textos del Sankey, etc.). El módulo `mod_analisis_*()` interpreta
### estos campos y delega los cómputos comunes a utils_analisis.R.
###
### Los datasets se referencian como funciones lazy (no por valor) para
### que el toggle intertrim/anual y, en formalidad, el toggle
### clásica/ampliada elijan el dataframe correcto en runtime.


### ============================================================================
### Helpers internos compartidos por los 3 configs
### ============================================================================

### Etiqueta de serie para Película en el patrón "% de X que (siguen|pasan a) Y".
### Lo usan cat_ocup y formalidad. cond_act tiene su propia versión con sustantivos
### abstractos (Inactividad / Ocupación / Desocupación).
.etiqueta_serie_plural_default <- function(from, to, plural_fn) {
  partir_de <- gsub("_t0$", "", from)
  ir_a      <- gsub("_t1$", "", to)
  partir_de_h <- plural_fn(partir_de)
  ir_a_h      <- plural_fn(ir_a)
  ifelse(
    partir_de == ir_a,
    glue::glue("% de {partir_de_h} que siguen como {ir_a_h}"),
    glue::glue("% de {partir_de_h} que pasan a {ir_a_h}")
  )
}


### ============================================================================
### Config: Condición de actividad (ESTADO)
### ============================================================================

config_cond_act <- list(
  nombre = "cond_act",

  ### --- Variable y etiquetas internas del panel ---
  var_panel = "ESTADO",
  ### NULL = usar el default de armo_base_panel (ESTADO + PONDERA)
  vars_panel_eph = NULL,
  etiquetas_codigo = c("Ocupado", "Desocupado", "Inactivo", "Trab_familiar"),

  ### --- Showcase icon del value box "Población" ---
  showcase_pob_icon = "activity",

  ### --- Choices de los selectInputs del UI ---
  choices_categoria_foto = c("Ocupados" = "Ocupado",
                              "Desocupados" = "Desocupado",
                              "Inactivos" = "Inactivo"),
  choices_pelicula_desde = c("Ocupación" = "Ocupado_t0",
                              "Desocupación" = "Desocupado_t0",
                              "Inactividad" = "Inactivo_t0"),
  default_pelicula_desde = "Desocupado_t0",
  choices_pelicula_hacia = c("Ocupación" = "Ocupado_t1",
                              "Desocupación" = "Desocupado_t1",
                              "Inactividad" = "Inactivo_t1"),
  default_pelicula_hacia = "Ocupado_t1",
  choices_tasas_categoria = c("Ocupados" = "Ocupado",
                               "Desocupados" = "Desocupado",
                               "Inactivos" = "Inactivo"),
  default_tasas_categoria = "Ocupado",
  ### Solo cond_act tiene multiselect de tipo de tasa (Persistencia/Salida/Entrada).
  ### En cat_ocup y formalidad la tab Tasas muestra siempre las 3 series.
  incluir_selector_tipo_tasa = TRUE,

  ### --- Sankey ---
  titulo_sankey = "Flujo de la condición de actividad.",
  sankey_nodes_labels = c("Ocupados", "Desocupados", "Inactivos", "Trab. familiares"),

  ### --- Etiquetas humanas para los outputs de la Foto ---
  ### Devuelve el texto para `Población: ...` en el value box.
  pob_label_fn = function(input, definicion = NULL) {
    fem <- switch(input$category,
                  Ocupado = "Ocupada",
                  Desocupado = "Desocupada",
                  Inactivo = "Inactiva")
    paste("Población:", fem)
  },

  ### Devuelve el `name` del Sankey según sentido (t_anterior/t_posterior).
  sentido_label_fn = function(input, sentido_t, definicion = NULL) {
    cat_lab <- switch(input$category,
                      Ocupado = "Ocupación",
                      Desocupado = "Desocupación",
                      Inactivo = "Inactividad")
    if (sentido_t == "t_anterior") {
      glue::glue("Flujo desde la {cat_lab}")
    } else {
      glue::glue("Flujo hacia la {cat_lab}")
    }
  },

  ### Etiqueta legible de cada serie de Película. cond_act usa sustantivos
  ### abstractos: "% de Desocupados que pasan a la Inactividad".
  pelicula_serie_label_fn = function(from, to) {
    dplyr::case_when(
      from == "Desocupado_t0" & to == "Inactivo_t1"  ~ "% de Desocupados que pasan a la Inactividad",
      from == "Desocupado_t0" & to == "Desocupado_t1" ~ "% de Desocupados que siguen Desocupados",
      from == "Desocupado_t0" & to == "Ocupado_t1"   ~ "% de Desocupados que pasan a la Ocupación",
      from == "Ocupado_t0"    & to == "Inactivo_t1"  ~ "% de Ocupados que pasan a la Inactividad",
      from == "Ocupado_t0"    & to == "Desocupado_t1" ~ "% de Ocupados que pasan a la Desocupación",
      from == "Ocupado_t0"    & to == "Ocupado_t1"   ~ "% de Ocupados que siguen Ocupados",
      from == "Inactivo_t0"   & to == "Inactivo_t1"  ~ "% de Inactivos que siguen Inactivos",
      from == "Inactivo_t0"   & to == "Desocupado_t1" ~ "% de Inactivos que pasan a la Desocupación",
      from == "Inactivo_t0"   & to == "Ocupado_t1"   ~ "% de Inactivos que pasan a la Ocupación"
    )
  },

  ### Caption del chart de Tasas según la categoría seleccionada.
  tasas_caption_fn = function(input, definicion = NULL) {
    paste0(
      "Tasas de movilidad por panel para los ",
      switch(input$tasas_category,
             Ocupado = "Ocupados",
             Desocupado = "Desocupados",
             Inactivo = "Inactivos"),
      ". Elaboración propia en base a EPH-INDEC."
    )
  },

  ### --- Caption extra del Sankey (formalidad lo usa para definición) ---
  caption_sankey_extra_fn = NULL,

  ### --- Datasets históricos lazy ---
  pelicula_df_fn = function(tipo_duo, definicion = NULL) {
    if (tipo_duo == "anual") df_cond_act_anual else df_cond_act
  },
  tasas_df_fn = function(tipo_duo, definicion = NULL) {
    if (tipo_duo == "anual") df_tasas_cond_act_anual else df_tasas_cond_act
  },

  ### --- Cómputo de población N para el value box principal ---
  ### Cond_act usa el atajo del parquet pre-computado df_tasas_mt
  ### (calculado una sola vez en ETL/03-update_data.R).
  pob_n_fn = function(input, anio_ant, trim_ant, anio_post, trim_post,
                      tipo_duo, var_panel = NULL, definicion = NULL) {
    categoria_lab <- switch(input$category,
                            Ocupado = "Ocupación",
                            Desocupado = "Desocupación",
                            Inactivo = "Inactividad")
    data <- arrow::read_parquet("data_output/df_tasas_mt.parquet") |>
      dplyr::filter(ANO4 == anio_ant & TRIMESTRE == trim_ant) |>
      dplyr::pull(switch(categoria_lab,
                         Ocupación = "pob_ocupada",
                         Desocupación = "pob_desocupada",
                         Inactividad = "pob_inactiva"))
    format(data, big.mark = ".", decimal.mark = ",")
  },

  ### --- Toggle definición (solo formalidad lo usa) ---
  incluir_toggle_definicion = FALSE,

  ### --- Tab "Comparar" funcional (solo cond_act por ahora) ---
  incluir_comparar_funcional = TRUE,

  ### --- ¿Mostrar plotBand de pandemia en el line chart? ---
  ### En cond_act y cat_ocup depende solo de si se ven todos los trimestres.
  mostrar_pandemia_fn = function(input, dim, definicion = NULL) {
    selector <- if (dim == "tasas") input$tasas_duo else input$duo
    selector == "todos"
  },

  ### --- Validación pre-render (formalidad ampliada lo usa) ---
  ### Devuelve string con mensaje de error o NULL si todo OK.
  validate_pre_render_fn = NULL
)


### ============================================================================
### Config: Categoría ocupacional (CAT_OCUP)
### ============================================================================

config_cat_ocup <- local({
  ### Helpers locales para etiquetas singular/plural de las 4 categorías.
  plural <- function(cat) {
    switch(cat,
           Patron = "Patrones",
           Cuenta_propia = "Cuenta propia",
           Asalariado = "Asalariados",
           TFSR = "Trab familiares")
  }

  list(
    nombre = "cat_ocup",

    var_panel = "CAT_OCUP",
    vars_panel_eph = c("ESTADO", "CAT_OCUP", "PONDERA"),
    etiquetas_codigo = c("Patron", "Cuenta_propia", "Asalariado", "TFSR"),

    showcase_pob_icon = "person-badge",

    choices_categoria_foto = c("Patrones" = "Patron",
                                "Cuenta propia" = "Cuenta_propia",
                                "Asalariados" = "Asalariado",
                                "Trab familiares" = "TFSR"),
    choices_pelicula_desde = c("Patrones" = "Patron_t0",
                                "Cuenta propia" = "Cuenta_propia_t0",
                                "Asalariados" = "Asalariado_t0",
                                "Trab familiares" = "TFSR_t0"),
    default_pelicula_desde = "Asalariado_t0",
    choices_pelicula_hacia = c("Patrones" = "Patron_t1",
                                "Cuenta propia" = "Cuenta_propia_t1",
                                "Asalariados" = "Asalariado_t1",
                                "Trab familiares" = "TFSR_t1"),
    default_pelicula_hacia = c("Cuenta_propia_t1", "Patron_t1"),
    choices_tasas_categoria = c("Patrones" = "Patron",
                                 "Cuenta propia" = "Cuenta_propia",
                                 "Asalariados" = "Asalariado",
                                 "Trab familiares" = "TFSR"),
    default_tasas_categoria = "Asalariado",
    incluir_selector_tipo_tasa = FALSE,

    titulo_sankey = "Movilidad entre categorías ocupacionales.",
    sankey_nodes_labels = c("Patrones", "Cuenta propia",
                             "Asalariados", "Trab. familiares"),

    pob_label_fn = function(input, definicion = NULL) {
      paste0("Población: ", plural(input$category))
    },

    sentido_label_fn = function(input, sentido_t, definicion = NULL) {
      cat_plural <- plural(input$category)
      if (sentido_t == "t_anterior") {
        glue::glue("Flujo desde {cat_plural}")
      } else {
        glue::glue("Flujo hacia {cat_plural}")
      }
    },

    pelicula_serie_label_fn = function(from, to) {
      .etiqueta_serie_plural_default(from, to, plural)
    },

    tasas_caption_fn = function(input, definicion = NULL) {
      paste0(
        "Tasas de movilidad por panel para los ",
        plural(input$tasas_category),
        ". Elaboración propia en base a EPH-INDEC."
      )
    },

    caption_sankey_extra_fn = NULL,

    pelicula_df_fn = function(tipo_duo, definicion = NULL) {
      if (tipo_duo == "anual") df_cat_ocup_anual else df_cat_ocup
    },
    tasas_df_fn = function(tipo_duo, definicion = NULL) {
      if (tipo_duo == "anual") df_tasas_cat_ocup_anual else df_tasas_cat_ocup
    },

    ### Cat_ocup arma el panel y suma PONDERA filtrando por código.
    pob_n_fn = function(input, anio_ant, trim_ant, anio_post, trim_post,
                        tipo_duo, var_panel = "CAT_OCUP", definicion = NULL) {
      df_panel <- armo_base_panel(
        anio_0 = anio_ant, trimestre_0 = trim_ant,
        anio_1 = anio_post, trimestre_1 = trim_post,
        variables = c("ESTADO", "CAT_OCUP", "PONDERA"),
        window = tipo_duo
      )
      codigo <- match(input$category,
                      c("Patron", "Cuenta_propia", "Asalariado", "TFSR"))
      n_pob <- df_panel |>
        dplyr::filter(CAT_OCUP == codigo) |>
        dplyr::summarise(n = sum(PONDERA, na.rm = TRUE)) |>
        dplyr::pull(n)
      format(n_pob, big.mark = ".", decimal.mark = ",")
    },

    incluir_toggle_definicion = FALSE,
    incluir_comparar_funcional = FALSE,

    mostrar_pandemia_fn = function(input, dim, definicion = NULL) {
      selector <- if (dim == "tasas") input$tasas_duo else input$duo
      selector == "todos"
    },

    validate_pre_render_fn = NULL
  )
})


### ============================================================================
### Config: Formalidad (Formal/Informal con toggle clásica/ampliada)
### ============================================================================

config_formalidad <- local({
  plural <- function(cat) {
    switch(cat,
           Formal = "Formales",
           Informal = "Informales")
  }

  ### Helpers que dependen del toggle definicion.
  resolver_var_panel <- function(definicion) {
    if (definicion == "ampliada") "formalidad_ampliada" else "formalidad"
  }
  resolver_universo <- function(definicion) {
    if (definicion == "ampliada") "ocupados" else "asalariados"
  }
  resolver_caption_def <- function(definicion) {
    if (definicion == "ampliada") {
      "Definición ampliada (OIT 2023, EPH 2023+): asalariados con PP07H + cuenta propia/patrones con PP05I/PP05K."
    } else {
      "Definición clásica EPH: solo asalariados (CAT_OCUP=3) vía PP07H."
    }
  }

  list(
    nombre = "formalidad",

    ### El var_panel REAL se resuelve en runtime por el toggle. Acá
    ### dejamos el default ("formalidad" = clásica) para inicialización.
    var_panel = "formalidad",
    vars_panel_eph = c("ESTADO", "CAT_OCUP", "PP07H", "PP05I", "PP05K",
                        "formalidad", "formalidad_ampliada", "PONDERA"),
    etiquetas_codigo = c("Formal", "Informal"),

    showcase_pob_icon = "person-vcard",

    choices_categoria_foto = c("Formales" = "Formal",
                                "Informales" = "Informal"),
    choices_pelicula_desde = c("Formales" = "Formal_t0",
                                "Informales" = "Informal_t0"),
    default_pelicula_desde = "Informal_t0",
    choices_pelicula_hacia = c("Formales" = "Formal_t1",
                                "Informales" = "Informal_t1"),
    default_pelicula_hacia = "Formal_t1",
    choices_tasas_categoria = c("Formales" = "Formal",
                                 "Informales" = "Informal"),
    default_tasas_categoria = "Formal",
    incluir_selector_tipo_tasa = FALSE,

    titulo_sankey = "Movilidad entre Formales e Informales.",
    sankey_nodes_labels = c("Formales", "Informales"),

    pob_label_fn = function(input, definicion = NULL) {
      universo <- resolver_universo(definicion %||% "clasica")
      paste0(stringr::str_to_sentence(universo), " ", plural(input$category))
    },

    sentido_label_fn = function(input, sentido_t, definicion = NULL) {
      universo <- resolver_universo(definicion %||% "clasica")
      cat_plural <- plural(input$category)
      if (sentido_t == "t_anterior") {
        glue::glue("Flujo desde {universo} {cat_plural}")
      } else {
        glue::glue("Flujo hacia {universo} {cat_plural}")
      }
    },

    pelicula_serie_label_fn = function(from, to) {
      .etiqueta_serie_plural_default(from, to, plural)
    },

    tasas_caption_fn = function(input, definicion = NULL) {
      def <- definicion %||% "clasica"
      paste0(
        "Tasas de movilidad para asalariados/ocupados ",
        plural(input$tasas_category),
        " (", def, "). Elaboración propia en base a EPH-INDEC."
      )
    },

    ### Caption extra del Sankey: agrega la nota de definición clásica/ampliada.
    caption_sankey_extra_fn = function(input, definicion = NULL) {
      resolver_caption_def(definicion %||% "clasica")
    },

    pelicula_df_fn = function(tipo_duo, definicion = NULL) {
      def <- definicion %||% "clasica"
      if (def == "ampliada") {
        if (tipo_duo == "anual") df_formalidad_ampliada_anual else df_formalidad_ampliada
      } else {
        if (tipo_duo == "anual") df_formalidad_anual else df_formalidad
      }
    },
    tasas_df_fn = function(tipo_duo, definicion = NULL) {
      def <- definicion %||% "clasica"
      if (def == "ampliada") {
        if (tipo_duo == "anual") df_tasas_formalidad_amp_anual else df_tasas_formalidad_amp
      } else {
        if (tipo_duo == "anual") df_tasas_formalidad_anual else df_tasas_formalidad
      }
    },

    pob_n_fn = function(input, anio_ant, trim_ant, anio_post, trim_post,
                        tipo_duo, var_panel = NULL, definicion = NULL) {
      vp <- var_panel %||% resolver_var_panel(definicion %||% "clasica")
      df_panel <- armo_base_panel(
        anio_0 = anio_ant, trimestre_0 = trim_ant,
        anio_1 = anio_post, trimestre_1 = trim_post,
        variables = c("ESTADO", "CAT_OCUP", "PP07H", "PP05I", "PP05K",
                      "formalidad", "formalidad_ampliada", "PONDERA"),
        window = tipo_duo
      )
      codigo <- match(input$category, c("Formal", "Informal"))
      n_pob <- df_panel |>
        dplyr::filter(.data[[vp]] == codigo) |>
        dplyr::summarise(n = sum(PONDERA, na.rm = TRUE)) |>
        dplyr::pull(n)
      if (length(n_pob) == 0 || is.na(n_pob)) {
        "—"
      } else {
        format(n_pob, big.mark = ".", decimal.mark = ",")
      }
    },

    incluir_toggle_definicion = TRUE,
    incluir_comparar_funcional = FALSE,

    ### En formalidad ampliada NO mostramos el plotBand de pandemia porque
    ### la definición ampliada arranca en 2023-T4 (post pandemia).
    mostrar_pandemia_fn = function(input, dim, definicion = NULL) {
      selector <- if (dim == "tasas") input$tasas_duo else input$duo
      def <- definicion %||% "clasica"
      selector == "todos" && def == "clasica"
    },

    ### Validación pre-render para definición ampliada: si no hay datos
    ### en el panel seleccionado (panel pre-2023-T4), devolver mensaje.
    ### El módulo lo pasa a shiny::validate() con shiny::need(). Devuelve
    ### NULL si la validación pasa.
    validate_pre_render_fn = function(input, df_panel, definicion = NULL) {
      def <- definicion %||% "clasica"
      if (def != "ampliada") return(NULL)
      n_validos <- df_panel |>
        dplyr::filter(!is.na(formalidad_ampliada)) |>
        nrow()
      if (n_validos > 0) return(NULL)
      "La definición ampliada está disponible desde 2023-T4. Elegí un panel más reciente o cambiá a definición clásica."
    },

    ### Helpers expuestos para uso interno del módulo (resuelven el toggle).
    .resolver_var_panel = resolver_var_panel,
    .resolver_universo  = resolver_universo
  )
})


### ============================================================================
### Operador %||% (rlang) — fallback si no está cargado
### ============================================================================

if (!exists("%||%")) {
  `%||%` <- function(a, b) if (is.null(a)) b else a
}
