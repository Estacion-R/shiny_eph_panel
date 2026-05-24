### Módulo del "Armador de panel" (issue #77).
###
### Reemplaza a la sección "Datos descargables" (R/panel_descarga.R): es la
### misma descarga del panel longitudinal, ahora con filtros. El usuario arma
### su propio subconjunto aplicando cortes y se lo lleva en Parquet/CSV.
###
### Fases implementadas (ver DISENO_ARMADOR_PANEL.md):
###   F1 · UI: selector de dataset (intertrim/anual) + toggle global t0/t1 +
###        4 filtros (Sexo, Edad, Condición de actividad, Categoría ocupacional).
###        Server: query Arrow LAZY filtrada server-side + conteo reactivo.
###   F2 · Preview (gt, primeras 20 filas) + warning de muestra chica + descarga
###        del subconjunto filtrado (Parquet + CSV gzip) con collect() bajo demanda.
###
### Principio anti-OOM: el collect() completo ocurre ÚNICAMENTE dentro del
### downloadHandler (al apretar Descargar). El conteo (nrow) y el preview
### (head 20) son baratos sobre la query lazy y no materializan el panel entero.
###
### Preview con gt (no DT): el repo ya carga gt y mantiene el footprint de RAM
### al mínimo para el free tier de shinyapps.io (decisión 2026-05-23).
###
### Pendiente F3 (integración al hub): montar el módulo en una vista, retirar
### la tarjeta "Datos descargables", preservar diccionario + aviso metodológico,
### y estilar las clases armador-* en www/style.css.
###
### Aglomerado y Pobreza quedan fuera de scope (issue #78 fast-follow y v2/#30).


# Codificación de la EPH (fuente: diccionario en R/panel_descarga.R) ---------
#
# Cada filtro ofrece sólo las categorías con significado analítico. Los códigos
# residuales (CAT_OCUP 0/9 = "no aplica/Ns-Nr", CH04 0 = registro espurio) no se
# listan: si el usuario no selecciona nada en un filtro, ese filtro no se aplica
# y esos registros quedan incluidos (caso "sin filtros = panel completo").

ARMADOR_SEXO_CHOICES <- c("Varón" = "1", "Mujer" = "2")

ARMADOR_ESTADO_CHOICES <- c(
  "Ocupado"          = "1",
  "Desocupado"       = "2",
  "Inactivo"         = "3",
  "Menor de 10 años" = "4"
)

ARMADOR_CATOCUP_CHOICES <- c(
  "Patrón"        = "1",
  "Cuenta propia" = "2",
  "Asalariado"    = "3",
  "Trab. familiar" = "4"
)

### Trimestre del inicio del dúo (trim_0 ∈ 1:4). Filtro estable sobre t0.
ARMADOR_TRIM_CHOICES <- c("T1" = "1", "T2" = "2", "T3" = "3", "T4" = "4")

### Años del inicio del dúo (anio_0) disponibles, como opciones del multi-select.
### Se derivan del global anios_disponibles (ETL/01-extract.R), que cubre el
### superset intertrim+anual. Fallback 2003-2025 si el global no existe (tests
### aislados). Multi-select: el usuario puede elegir años no contiguos; ninguno
### seleccionado = todos los años (preserva "sin filtros = panel completo").
armador_anios_opciones <- function() {
  if (exists("anios_disponibles", envir = .GlobalEnv) &&
      length(get("anios_disponibles", envir = .GlobalEnv)) > 0) {
    sort(as.integer(get("anios_disponibles", envir = .GlobalEnv)))
  } else {
    2003:2025
  }
}

### Rango del slider de edad. CH06 en el microdato va de -1 (código EPH "menor
### de 1 año") a 110. El slider se presenta en [0, 110] (números limpios) y
### sólo filtra cuando el usuario lo mueve fuera del rango completo: en la
### posición default no se aplica ningún corte de edad, así los registros con
### CH06 = -1 quedan incluidos y se preserva el "panel completo".
ARMADOR_EDAD_MIN <- 0L
ARMADOR_EDAD_MAX <- 110L

### Umbral de muestra chica. Por debajo se muestra un aviso de cautela
### (criterio alineado con #29: subconjuntos con pocos casos son frágiles).
ARMADOR_N_MIN <- 100L


### downloadButton con tracking GA4 client-side. Mismo patrón que la sección
### Datos (R/panel_descarga.R): el onclick burbujea desde el wrapper, dispara
### el evento gtag y la descarga sigue. Si gtag no está cargado (consent
### denegado o GA4 deshabilitado), el evento se descarta sin romper nada.
### Helper local porque el Armador reemplazará a panel_descarga.R en F3.
armador_download_btn <- function(output_id, label, format, icon_name) {
  onclick_js <- sprintf(
    "if(typeof gtag==='function'){gtag('event','dataset_download',{dataset:'armador',format:'%s',source:'armador'});}",
    format
  )
  tags$div(
    class   = "descarga-btn-wrapper",
    onclick = onclick_js,
    shiny::downloadButton(
      output_id,
      label = label,
      icon  = shiny::icon(icon_name),
      class = "btn-descarga"
    )
  )
}


### Esquema de salida (preview + descarga) -----------------------------------
###
### Las variables que VARÍAN entre olas llevan sufijo _t0 explícito, espejo de
### las _t1, para que el dataset sea simétrico y sin ambigüedad. Las claves de
### persona (CODUSU, NRO_HOGAR, COMPONENTE), el id del dúo (Periodo) y el flag
### `consistencia` no llevan sufijo (no son específicas de un momento).
ARMADOR_VARS_T0 <- c("ANO4", "TRIMESTRE", "CH04", "CH06", "ESTADO", "CAT_OCUP",
                     "PP07H", "PP05I", "PP05K", "formalidad",
                     "formalidad_ampliada", "PONDERA")

### Renombra el panel al esquema de salida: descarta anio_0/trim_0 (duplican a
### ANO4/TRIMESTRE, verificado: 0 diferencias) y sufija las vars t0 con _t0.
### El filtrado interno sigue usando anio_0/trim_0; el rename es sólo de salida.
armador_nombres_salida <- function(df) {
  df |>
    dplyr::select(-dplyr::any_of(c("anio_0", "trim_0"))) |>
    dplyr::rename_with(~ paste0(.x, "_t0"), dplyr::any_of(ARMADOR_VARS_T0))
}

### Diccionario de salida: reusa las descripciones canónicas de
### columnas_panel_runtime (R/panel_descarga.R), sin las redundantes y con _t0.
armador_diccionario_salida <- function() {
  columnas_panel_runtime |>
    dplyr::filter(!Variable %in% c("anio_0", "trim_0")) |>
    dplyr::mutate(Variable = ifelse(Variable %in% ARMADOR_VARS_T0,
                                    paste0(Variable, "_t0"), Variable))
}


### Etiqueta las variables categóricas (códigos → texto) en t0 Y t1, y las deja
### como factor para que la etiqueta viaje al CSV/parquet/preview.
###
### eph::organize_labels() pone las etiquetas canónicas de la EPH, pero sólo
### reconoce los nombres estándar (ESTADO, CAT_OCUP, CH04, PP07H, PP05I, PP05K)
### y deja la columna como `labelled`. Para etiquetar también las _t1, las
### renombramos a su nombre base, las etiquetamos y restauramos el sufijo.
### `formalidad`/`formalidad_ampliada` se construyen en el ETL (no son vars EPH),
### así que organize_labels no las cubre: las mapeamos a mano.
armador_etiquetar <- function(df) {
  vars_eph <- c("ESTADO", "CAT_OCUP", "CH04", "PP07H", "PP05I", "PP05K")

  ### t0: nombres EPH estándar, directo.
  df <- suppressWarnings(eph::organize_labels(df, type = "individual"))

  ### t1: strip _t1 → etiquetar → restaurar _t1.
  t1_presentes <- intersect(paste0(vars_eph, "_t1"), names(df))
  if (length(t1_presentes) > 0) {
    aux <- df |>
      dplyr::select(dplyr::all_of(t1_presentes)) |>
      dplyr::rename_with(~ sub("_t1$", "", .x))
    aux <- suppressWarnings(eph::organize_labels(aux, type = "individual")) |>
      dplyr::rename_with(~ paste0(.x, "_t1"))
    df[t1_presentes] <- aux
  }

  ### labelled → factor (texto en CSV). El paquete `labelled` no está en runtime;
  ### detectamos las columnas por clase y usamos haven::as_factor.
  df <- df |>
    dplyr::mutate(dplyr::across(dplyr::where(~ inherits(.x, "labelled")),
                                haven::as_factor))

  ### formalidad / formalidad_ampliada (custom): mapeo manual a factor.
  mapa_form <- c("1" = "Formal", "2" = "Informal")
  cols_form <- intersect(
    c("formalidad", "formalidad_t1", "formalidad_ampliada", "formalidad_ampliada_t1"),
    names(df))
  for (cc in cols_form) {
    df[[cc]] <- factor(unname(mapa_form[as.character(df[[cc]])]),
                       levels = c("Formal", "Informal"))
  }
  df
}


### Prepara el dataset de salida (preview + descarga): etiqueta (opcional) y
### aplica el esquema _t0/_t1. El etiquetado va ANTES del renombrado porque
### organize_labels usa los nombres EPH estándar (ESTADO, CH04, …), no los _t0.
armador_preparar_salida <- function(df, etiquetar = FALSE) {
  if (isTRUE(etiquetar)) df <- armador_etiquetar(df)
  armador_nombres_salida(df)
}


### Resumen en lenguaje natural -----------------------------------------------
###
### Etiquetas (con concordancia de género) para describir los estados en la
### oración resumen. f = femenino (concuerda con "mujeres"/"personas"),
### m = masculino (sólo cuando se filtra únicamente "Varón").
ARMADOR_LBL_CONDACT <- list(
  "1" = c(f = "ocupadas",    m = "ocupados"),
  "2" = c(f = "desocupadas", m = "desocupados"),
  "3" = c(f = "inactivas",   m = "inactivos"),
  "4" = c(f = "menores de 10 años", m = "menores de 10 años")
)
ARMADOR_LBL_CATOCUP <- list(
  "1" = c(f = "patronas",     m = "patrones"),
  "2" = c(f = "cuentapropistas", m = "cuentapropistas"),
  "3" = c(f = "asalariadas",  m = "asalariados"),
  "4" = c(f = "trabajadoras familiares", m = "trabajadores familiares")
)

### Traduce la selección de filtros a una oración legible, para que la persona
### entienda qué subconjunto está por descargar. Se adapta al toggle t0/t1
### (destino vs origen) y degrada con gracia ante multi-selección o filtros
### vacíos. La frase del "trimestre siguiente" sólo es exacta cuando hay un único
### año y un único trimestre; si no, usa una forma genérica.
armador_frase_filtros <- function(panel, momento, anios, trims, sexo, edad,
                                  condact, catocup) {

  unir <- function(x, conector = "y") {
    x <- as.character(x)
    if (length(x) == 0) return("")
    if (length(x) == 1) return(x)
    paste(paste(head(x, -1), collapse = ", "), conector, tail(x, 1))
  }

  ### Género para la concordancia: sólo "Varón" único → masculino; en cualquier
  ### otro caso femenino (concuerda con "mujeres" o con "personas").
  gen <- if (length(sexo) == 1 && sexo == "1") "m" else "f"

  sujeto <- if (length(sexo) == 1 && sexo == "2") "las mujeres"
            else if (length(sexo) == 1 && sexo == "1") "los varones"
            else "las personas"

  edad_txt <- if (is.null(edad) ||
                  (edad[1] <= ARMADOR_EDAD_MIN && edad[2] >= ARMADOR_EDAD_MAX)) {
    "de todas las edades"
  } else if (edad[1] <= ARMADOR_EDAD_MIN) {
    paste0("de hasta ", edad[2], " años")
  } else if (edad[2] >= ARMADOR_EDAD_MAX) {
    paste0("de ", edad[1], " años o más")
  } else {
    paste0("de entre ", edad[1], " y ", edad[2], " años")
  }
  demografia <- paste(sujeto, edad_txt)

  ### Período del inicio del dúo (t0): año(s) + trimestre(s).
  anios_i <- sort(as.integer(anios))
  trims_i <- sort(as.integer(trims))
  trim_frase <- if (length(trims_i) == 1) paste0("el trimestre ", trims_i)
                else if (length(trims_i) > 1) paste0("los trimestres ", unir(trims_i))
                else NULL
  anio_frase <- if (length(anios_i) >= 1) unir(anios_i) else NULL
  periodo_t0 <- if (!is.null(trim_frase) && !is.null(anio_frase)) {
                  paste(trim_frase, "de", anio_frase)
                } else if (!is.null(trim_frase)) {
                  trim_frase
                } else if (!is.null(anio_frase)) {
                  paste("algún trimestre de", anio_frase)
                } else {
                  NULL
                }

  ### Estado (condición de actividad + categoría ocupacional), con género.
  ca <- if (length(condact) > 0) {
    unir(vapply(as.character(condact),
                function(k) ARMADOR_LBL_CONDACT[[k]][[gen]], character(1)), "o")
  } else NULL
  co <- if (length(catocup) > 0) {
    unir(vapply(as.character(catocup),
                function(k) ARMADOR_LBL_CATOCUP[[k]][[gen]], character(1)), "o")
  } else NULL
  estado <- if (!is.null(ca) && !is.null(co)) paste(ca, "y", co)
            else if (!is.null(ca)) ca
            else if (!is.null(co)) co
            else NULL

  ### Caso sin ningún filtro → panel completo.
  panel_txt <- if (identical(panel, "anual")) "interanual" else "intertrimestral"
  if (is.null(estado) && is.null(periodo_t0) &&
      length(sexo) == 0 && grepl("todas las edades", edad_txt)) {
    return(paste0("El panel ", panel_txt, " completo (sin filtros aplicados)."))
  }

  if (identical(momento, "t1")) {
    ### Estado al CIERRE (t1); el período filtra el inicio (t0) y observamos el
    ### origen.
    base <- paste0("Situación al inicio del dúo (",
                   if (!is.null(periodo_t0)) periodo_t0 else "cualquier trimestre",
                   ") para ", demografia)
    if (!is.null(estado)) base <- paste0(base, " que al cierre del dúo eran ", estado)
    return(paste0(base, "."))
  }

  ### Toggle t0: estado al INICIO (t0); observamos el destino (t1).
  frase_t1 <- if (length(anios_i) == 1 && length(trims_i) == 1) {
    y <- anios_i; q <- trims_i
    if (identical(panel, "anual")) paste0("el trimestre ", q, " de ", y + 1)
    else if (q < 4) paste0("el trimestre ", q + 1, " de ", y)
    else paste0("el trimestre 1 de ", y + 1)
  } else if (identical(panel, "anual")) {
    "el mismo trimestre del año siguiente"
  } else {
    "el trimestre siguiente"
  }
  ancla_t0 <- if (!is.null(periodo_t0)) paste("en", periodo_t0) else "al inicio del dúo"

  base <- paste0("Situación en ", frase_t1, " para ", demografia)
  if (!is.null(estado)) {
    base <- paste0(base, " que ", ancla_t0, " eran ", estado)
  } else if (!is.null(periodo_t0)) {
    base <- paste0(base, " con dúo iniciado en ", periodo_t0)
  }
  paste0(base, ".")
}


### Totales de referencia ANCLADOS AL PERÍODO seleccionado (año/trimestre de
### t0). Salen del histórico de calidad (df_calidad_panel / _anual, cargado en
### ETL/01-extract.R), filtrado por los mismos año(s)/trimestre(s) del Armador:
###   - t0    = sum(n_t0)     → muestra EPH observada en t0 para ese período
###             (el 100% de referencia, antes del apareo).
###   - match = sum(n_panel)  → dúos efectivamente apareados en ese período
###             (== nrow del panel runtime filtrado por período, verificado).
###             El resto de t0 se pierde por atrición (no aparece en t1).
### Sin filtro de período devuelve los totales de todos los dúos.
armador_totales_periodo <- function(panel, anios, trims) {
  nombre <- if (identical(panel, "anual")) "df_calidad_panel_anual" else "df_calidad_panel"
  if (!exists(nombre, envir = .GlobalEnv)) return(list(t0 = NA_real_, match = NA_real_))
  cal <- get(nombre, envir = .GlobalEnv)
  if (is.null(cal) || nrow(cal) == 0) return(list(t0 = NA_real_, match = NA_real_))
  if (length(anios) > 0) cal <- cal[cal$anio_0 %in% as.integer(anios), , drop = FALSE]
  if (length(trims) > 0) cal <- cal[cal$trim_0 %in% as.integer(trims), , drop = FALSE]
  list(t0 = sum(cal$n_t0, na.rm = TRUE), match = sum(cal$n_panel, na.rm = TRUE))
}

### Formatea un porcentaje en es-AR (coma decimal, 1 decimal). Valores muy
### chicos (>0 y <0,1) se muestran como "<0,1%" para no rondear a 0,0%.
armador_fmt_pct <- function(p) {
  if (is.na(p)) return("—")
  if (p > 0 && p < 0.1) return("<0,1%")
  paste0(format(round(p, 1), decimal.mark = ",", nsmall = 1, trim = TRUE), "%")
}


# UI -------------------------------------------------------------------------

mod_armador_ui <- function(id) {
  ns <- NS(id)

  tags$div(
    class = "armador",
    style = "max-width: 1100px;",

    ### Hero (reusa el estilo de la sección Datos).
    tags$div(
      class = "descarga-hero",
      tags$h2("Armá tu panel", class = "descarga-hero-title"),
      tags$p(
        class = "descarga-hero-subtitle",
        "Aplicá cortes sobre el panel longitudinal ya procesado y descargá ",
        "el subconjunto para tus propios análisis. Sin filtros, te llevás el ",
        "panel completo. El microdato está armado a partir de la ",
        tags$strong("EPH-INDEC"), "."
      )
    ),

    ### --- Ayuda: cómo leer el dataset (colapsable, cerrado por default) ---
    bslib::accordion(
      open  = FALSE,
      class = "armador-ayuda",
      bslib::accordion_panel(
        value = "ayuda-dataset",
        title = tagList(icon("circle-question"), " ¿Cómo leer este dataset?"),
        tags$p(
          "Es un ", tags$strong("panel longitudinal"), ": seguimos a las mismas ",
          "personas entre dos trimestres (", tags$strong("t0"), " = inicio del dúo, ",
          tags$strong("t1"), " = fin)."
        ),
        tags$ul(
          tags$li(
            tags$strong("Cada fila es una persona seguida entre t0 y t1."),
            " Sólo entran las que están presentes en ", tags$em("los dos"),
            " trimestres (las que la EPH pierde en el medio quedan afuera)."
          ),
          tags$li(
            "Cada variable que cambia en el tiempo viene en ",
            tags$strong("dos columnas"), ": ", tags$code("ESTADO_t0"),
            " (al inicio) y ", tags$code("ESTADO_t1"), " (al final). El ",
            "movimiento se lee comparando las dos dentro de la misma fila."
          ),
          tags$li(
            tags$code("CODUSU"), ", ", tags$code("NRO_HOGAR"), " y ",
            tags$code("COMPONENTE"), " identifican a la persona: son la clave con ",
            "la que se hace el pareo (match) entre los dos trimestres."
          ),
          tags$li(
            "Una misma persona puede aparecer en ", tags$strong("varias filas"),
            " si fue seguida en varios pares de trimestres (ej. ",
            tags$code("2023_t1-t2"), " y ", tags$code("2023_t2-t3"),
            "). Por eso contamos ", tags$em("personas-dúo"), ", no personas únicas."
          ),
          tags$li(
            "El flag ", tags$code("consistencia"), " marca filas donde una variable ",
            "que no debería cambiar (sexo, edad) cambió de forma imposible entre t0 y t1."
          )
        ),
        tags$p(
          class = "armador-ayuda-nota",
          "En los filtros: Año, Trimestre, Sexo y Edad miran siempre t0. ",
          "Condición de actividad y Categoría ocupacional miran t0 o t1 según el ",
          "toggle de abajo."
        )
      )
    ),

    ### --- Configuración global: dataset + momento del dúo -----------------
    tags$div(
      class = "armador-config",

      ### Selector de dataset: define qué parquet se filtra (intertrim vs anual).
      tags$div(
        class = "armador-config-item",
        radioButtons(
          inputId = ns("dataset"),
          label   = "Panel",
          choices = c(
            "Intertrimestral" = "trimestral",
            "Interanual"      = "anual"
          ),
          selected = "trimestral",
          inline   = TRUE
        ),
        tags$p(
          class = "armador-config-helper",
          tags$strong("Intertrimestral: "), "dúos T → T+1. ",
          tags$strong("Interanual: "), "mismo trimestre del año siguiente."
        )
      ),

      ### Toggle global t0/t1. Aplica SÓLO a las variables que cambian entre
      ### olas (Condición de actividad y Categoría ocupacional). Sexo y edad
      ### son estables y siempre se leen del inicio del dúo (t0).
      tags$div(
        class = "armador-config-item",
        tags$div(
          class = "armador-momento-label",
          tags$span("¿En qué momento del dúo?"),
          bslib::tooltip(
            bsicons::bs_icon(
              "info-circle",
              style = "margin-left: 6px; color: #405BFF; cursor: help;"
            ),
            tags$div(
              "Elige si los filtros de ", tags$strong("Condición de actividad"),
              " y ", tags$strong("Categoría ocupacional"), " miran el estado de ",
              "la persona al ", tags$strong("inicio"), " del dúo (t0) o al ",
              tags$strong("final"), " (t1).", tags$br(), tags$br(),
              tags$strong("Parado en t0"), " fijás el punto de partida y mirás ",
              tags$strong("hacia dónde van"), " las personas (su destino en t1).",
              tags$br(), tags$br(),
              tags$strong("Parado en t1"), " fijás el punto de llegada y mirás ",
              tags$strong("de dónde vienen"), " (su origen en t0).",
              tags$br(), tags$br(),
              "Sexo, edad, año y trimestre se leen siempre del inicio del dúo (t0)."
            ),
            placement = "right"
          )
        ),
        radioButtons(
          inputId = ns("momento"),
          label   = NULL,
          choices = c(
            "Inicio del dúo (t0)" = "t0",
            "Fin del dúo (t1)"    = "t1"
          ),
          selected = "t0",
          inline   = TRUE
        )
      )
    ),

    ### --- Panel de filtros ------------------------------------------------
    ### Grilla responsiva de 4 filtros. Categóricos = checkboxGroupInput (todas
    ### las opciones visibles; ninguna marcada = no filtra esa variable). Edad =
    ### range slider sobre t0.
    bslib::card(
      class = "armador-filtros-card",
      bslib::card_header(
        icon("sliders"),
        tags$span("Filtros", style = "margin-left: 0.4rem;")
      ),
      bslib::layout_columns(
        col_widths = c(4, 4, 4, 4, 4, 4),

        ### Año del inicio del dúo (anio_0, estable → t0). Multi-select: permite
        ### elegir años no contiguos. Ninguno seleccionado = todos (panel completo).
        tags$div(
          class = "armador-filtro",
          selectInput(
            inputId  = ns("anio"),
            label    = "Año (t0)",
            choices  = armador_anios_opciones(),
            selected = character(0),
            multiple = TRUE
          )
        ),

        ### Trimestre del inicio del dúo (trim_0, estable → t0).
        tags$div(
          class = "armador-filtro",
          checkboxGroupInput(
            inputId  = ns("trimestre"),
            label    = "Trimestre (t0)",
            choices  = ARMADOR_TRIM_CHOICES,
            selected = character(0),
            inline   = TRUE
          )
        ),

        tags$div(
          class = "armador-filtro",
          checkboxGroupInput(
            inputId  = ns("sexo"),
            label    = "Sexo (t0)",
            choices  = ARMADOR_SEXO_CHOICES,
            selected = character(0)
          )
        ),

        tags$div(
          class = "armador-filtro",
          sliderInput(
            inputId = ns("edad"),
            label   = "Edad (t0)",
            min     = ARMADOR_EDAD_MIN,
            max     = ARMADOR_EDAD_MAX,
            value   = c(ARMADOR_EDAD_MIN, ARMADOR_EDAD_MAX),
            step    = 1,
            ticks   = FALSE
          )
        ),

        tags$div(
          class = "armador-filtro",
          checkboxGroupInput(
            inputId  = ns("cond_act"),
            label    = "Condición de actividad (t0)",
            choices  = ARMADOR_ESTADO_CHOICES,
            selected = character(0)
          )
        ),

        tags$div(
          class = "armador-filtro",
          checkboxGroupInput(
            inputId  = ns("cat_ocup"),
            label    = "Categoría ocupacional (t0)",
            choices  = ARMADOR_CATOCUP_CHOICES,
            selected = character(0)
          )
        )
      ),
      tags$p(
        class = "armador-filtros-nota",
        "Dejá un filtro sin marcar (o el slider en su rango completo) para incluir todo."
      )
    ),

    ### --- Descriptor de lo que se va a descargar --------------------------
    ### Justo debajo de los filtros: oración en lenguaje natural + filas + % de
    ### muestra (sobre el panel y sobre la EPH). Descriptor completo del
    ### subconjunto. Ver armador_frase_filtros() y armador_totales().
    uiOutput(ns("frase_filtros")),

    ### Warning de muestra chica / subconjunto vacío (aparece sólo si el
    ### subconjunto es vacío o tiene menos de ARMADOR_N_MIN filas).
    uiOutput(ns("warning_n")),

    ### --- Formato de salida: con/sin etiquetas ----------------------------
    ### Aplica al preview Y a la descarga. "Con etiquetas" reemplaza los códigos
    ### por texto (Ocupado, Mujer, …); "Sin etiquetas" deja los códigos numéricos.
    tags$div(
      class = "armador-etiquetas",
      radioButtons(
        inputId  = ns("etiquetas"),
        label    = "Categorías de las variables:",
        choices  = c("Con etiquetas" = "si", "Sin etiquetas (códigos)" = "no"),
        selected = "si",
        inline   = TRUE
      ),
      tags$span(class = "armador-etiquetas-nota",
                "Aplica al preview y a la descarga.")
    ),

    ### --- Preview: primeras 20 filas del subconjunto (gt interactivo) ------
    ### head(20) |> collect() es barato. gt::opt_interactive() hace las columnas
    ### ordenables (clic en el encabezado) usando reactable por debajo.
    bslib::card(
      class = "armador-preview-card",
      bslib::card_header(
        icon("eye"),
        tags$span("Vista previa", style = "margin-left: 0.4rem;"),
        tags$span(class = "armador-preview-sub",
                  "primeras 20 filas · clic en una columna para ordenar")
      ),
      tags$div(
        class = "armador-preview-scroll",
        gt::gt_output(ns("preview"))
      )
    ),

    ### --- Descarga del subconjunto filtrado -------------------------------
    ### El collect() completo ocurre dentro del downloadHandler (server),
    ### nunca antes. Se llevan TODAS las columnas del panel (MVP).
    tags$div(
      class = "armador-descarga",

      ### Advertencia metodológica EN el punto de descarga (antes era un aviso
      ### al pie, lejos de la acción). Lo clave queda visible; el detalle
      ### completo + la fuente van en el popover, a un clic.
      tags$div(
        class = "armador-aviso-descarga",
        icon("triangle-exclamation"),
        tags$span(
          tags$strong("Antes de descargar y usar estos datos"),
          ", tené en cuenta sus limitaciones: intervención INDEC (2007-2015), ",
          "panel balanceado (atrición) e inconsistencias entre t0 y t1. ",
          bslib::popover(
            tags$a(href = "#", class = "armador-aviso-link",
                   onclick = "return false;",
                   "Ver detalle"),
            title = "Limitaciones metodológicas",
            tags$ul(
              style = "padding-left: 1.1rem; margin-bottom: 0.5rem;",
              tags$li(
                tags$strong("Intervención INDEC 2007-2015: "),
                "el propio organismo desestima estas series para el análisis ",
                "del mercado de trabajo. Considerá excluirlas o reportarlas con reservas."
              ),
              tags$li(
                tags$strong("Panel balanceado: "),
                "sólo incluye personas presentes en t0 ", tags$em("y"), " en t1. ",
                "Las que la EPH pierde entre trimestres (atrición) quedan fuera."
              ),
              tags$li(
                tags$strong("Inconsistencias t0/t1: "),
                "el flag ", tags$code("consistencia"), " marca casos donde una ",
                "variable estable (sexo, edad) cambió de forma imposible."
              ),
              tags$li(
                tags$strong("Cobertura: "),
                "desde 2003-T1 hasta el último trimestre publicado por INDEC."
              )
            ),
            tags$p(
              style = "margin-bottom: 0;",
              tags$strong("Fuente: "),
              tags$a("INDEC · EPH",
                     href = "https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos",
                     target = "_blank"),
              " · Procesamiento con ",
              tags$a("{eph}", href = "https://docs.ropensci.org/eph/", target = "_blank"), "."
            ),
            placement = "top"
          )
        )
      ),

      tags$p(
        class = "armador-descarga-titulo",
        "Descargá tu panel armado con todas sus columnas:"
      ),
      tags$div(
        class = "armador-descarga-botones",
        armador_download_btn(ns("descarga_parquet"), "Parquet",
                             format = "parquet",  icon_name = "file-zipper"),
        armador_download_btn(ns("descarga_csv"), "CSV (gzip)",
                             format = "csv_gz",   icon_name = "file-csv")
      ),
      ### Diccionario de variables: metadata, no el dato filtrado. Se ofrece
      ### como descarga aparte (preserva la funcionalidad de la sección Datos).
      tags$p(
        class = "armador-descarga-extra",
        "¿Qué significa cada columna? Bajate el ",
        tags$span(
          class = "descarga-btn-wrapper",
          onclick = "if(typeof gtag==='function'){gtag('event','dataset_download',{dataset:'armador',format:'diccionario',source:'armador'});}",
          shiny::downloadLink(
            ns("descarga_diccionario"),
            label = "diccionario de variables (CSV)"
          )
        ), "."
      )
    )
  )
}


# Server ---------------------------------------------------------------------

mod_armador_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    ### Etiquetas de los filtros que dependen del toggle: reflejan el momento
    ### activo (t0/t1) en vivo, así el usuario ve sobre qué columna filtra
    ### (ESTADO vs ESTADO_t1, CAT_OCUP vs CAT_OCUP_t1). Las variables estables
    ### (año, trimestre, sexo, edad) ya rotulan "(t0)" fijo en la UI.
    observe({
      m <- if (identical(input$momento, "t1")) "t1" else "t0"
      updateCheckboxGroupInput(session, "cond_act",
                               label = paste0("Condición de actividad (", m, ")"))
      updateCheckboxGroupInput(session, "cat_ocup",
                               label = paste0("Categoría ocupacional (", m, ")"))
    })

    ### Dataset activo como objeto Arrow LAZY según el selector.
    ###
    ### Intertrim: df_panel_runtime ya está cargado al boot como Arrow Table
    ### (lazy view) en ETL/01-extract.R.
    ###
    ### Anual: se abre ON-DEMAND con arrow::open_dataset() (lazy real: sólo lee
    ### el footer y los row groups que matchean al filter). NO se mantiene la
    ### Table en memoria, mismo patrón anti-OOM que armo_base_panel(window =
    ### "anual"). Ver nota en ETL/99-functions.R.
    ds_activo <- reactive({
      if (identical(input$dataset, "anual")) {
        path <- if (exists("PATH_PANEL_RUNTIME_ANUAL", envir = .GlobalEnv)) {
          get("PATH_PANEL_RUNTIME_ANUAL", envir = .GlobalEnv)
        } else {
          "data_output/panel_runtime_anual.parquet"
        }
        validate(need(
          file.exists(path),
          "El panel interanual no está disponible. Correr ETL/09b-build_paneles_runtime_anual.R."
        ))
        arrow::open_dataset(path)
      } else {
        validate(need(
          exists("df_panel_runtime", envir = .GlobalEnv),
          "df_panel_runtime no disponible. Ejecutar ETL/01-extract.R."
        ))
        get("df_panel_runtime", envir = .GlobalEnv)
      }
    })

    ### Query Arrow LAZY filtrada. Construcción incremental: AND entre variables,
    ### OR dentro de cada una (vía %in%). Un filtro vacío no se aplica → sus
    ### categorías quedan incluidas (caso "sin filtros = panel completo").
    ###
    ### Para Condición de actividad y Categoría ocupacional, el toggle global
    ### elige la columna (ESTADO vs ESTADO_t1, CAT_OCUP vs CAT_OCUP_t1) con
    ### acceso programático .data[[col]] (nunca eval(parse())). Sexo y edad se
    ### filtran siempre sobre t0 (CH04, CH06).
    ###
    ### NO hay collect() acá: devuelve la query lazy para que la consuma el
    ### conteo (nrow), el preview (head) y, en F2, la descarga (collect completo).
    panel_filtrado <- reactive({
      q <- ds_activo()

      momento     <- if (identical(input$momento, "t1")) "t1" else "t0"
      col_estado  <- if (momento == "t1") "ESTADO_t1"   else "ESTADO"
      col_catocup <- if (momento == "t1") "CAT_OCUP_t1" else "CAT_OCUP"

      ### Año del inicio del dúo (anio_0, estable → t0). Multi-select: AND con
      ### el resto, OR entre los años elegidos. Ninguno = todos los años.
      if (length(input$anio) > 0) {
        vals_anio <- as.numeric(input$anio)
        q <- q |> dplyr::filter(anio_0 %in% vals_anio)
      }

      ### Trimestre del inicio del dúo (trim_0, estable → t0).
      if (length(input$trimestre) > 0) {
        vals_trim <- as.numeric(input$trimestre)
        q <- q |> dplyr::filter(trim_0 %in% vals_trim)
      }

      ### Sexo (CH04, estable → t0).
      if (length(input$sexo) > 0) {
        vals_sexo <- as.numeric(input$sexo)
        q <- q |> dplyr::filter(CH04 %in% vals_sexo)
      }

      ### Edad (CH06, estable → t0). Sólo se aplica si el slider se movió fuera
      ### del rango completo; en la posición default es un no-op (panel completo).
      edad <- input$edad
      if (!is.null(edad) &&
          (edad[1] > ARMADOR_EDAD_MIN || edad[2] < ARMADOR_EDAD_MAX)) {
        edad_lo <- edad[1]
        edad_hi <- edad[2]
        q <- q |> dplyr::filter(CH06 >= edad_lo, CH06 <= edad_hi)
      }

      ### Condición de actividad (ESTADO/ESTADO_t1 según toggle).
      if (length(input$cond_act) > 0) {
        vals_estado <- as.numeric(input$cond_act)
        q <- q |> dplyr::filter(.data[[col_estado]] %in% vals_estado)
      }

      ### Categoría ocupacional (CAT_OCUP/CAT_OCUP_t1 según toggle).
      if (length(input$cat_ocup) > 0) {
        vals_catocup <- as.numeric(input$cat_ocup)
        q <- q |> dplyr::filter(.data[[col_catocup]] %in% vals_catocup)
      }

      q
    })

    ### Conteo de filas del subconjunto. Barato sobre la query lazy. Cada fila
    ### es una persona seguida entre t0 y t1 (persona-dúo).
    n_filas <- reactive({
      nrow(panel_filtrado())
    })

    ### Caja "Estás por descargar": descriptor completo del subconjunto.
    ### Línea 1: la oración en lenguaje natural. Línea 2: filas + % sobre el
    ### panel balanceado y % sobre la muestra EPH original.
    output$frase_filtros <- renderUI({
      panel <- if (identical(input$dataset, "anual")) "anual" else "trimestral"
      txt <- armador_frase_filtros(
        panel   = panel,
        momento = if (identical(input$momento, "t1")) "t1" else "t0",
        anios   = input$anio,
        trims   = input$trimestre,
        sexo    = input$sexo,
        edad    = input$edad,
        condact = input$cond_act,
        catocup = input$cat_ocup
      )

      ### Embudo anclado al período (pensando en dúos). Denominador único: la
      ### muestra T0 (el total de casos), así cada nivel es subconjunto del
      ### anterior y el % siempre decrece:
      ###   1) muestra T0 del período (100%)
      ###   2) dúos apareados (el panel): match / T0
      ###   3) tu selección con el resto de los filtros: filtrado / T0
      n_filt <- n_filas()
      tp     <- armador_totales_periodo(panel, input$anio, input$trimestre)
      pct_match <- if (!is.na(tp$t0) && tp$t0 > 0) 100 * tp$match / tp$t0 else NA_real_
      pct_sel   <- if (!is.na(tp$t0) && tp$t0 > 0) 100 * n_filt   / tp$t0 else NA_real_
      fnum <- function(x) if (is.na(x)) "—" else format(x, big.mark = ".", decimal.mark = ",")
      hay_periodo <- length(input$anio) > 0 || length(input$trimestre) > 0

      fila_funnel <- function(label, valor, pct = NULL, final = FALSE) {
        tags$div(
          class = if (final) "armador-funnel-row armador-funnel-row-final" else "armador-funnel-row",
          tags$span(class = "armador-funnel-lbl", label),
          tags$span(class = "armador-funnel-val", valor),
          if (!is.null(pct)) tags$span(class = "armador-funnel-pct", pct)
        )
      }

      tags$div(
        class = "armador-frase",
        tags$div(
          class = "armador-frase-linea1",
          icon("quote-left", class = "armador-frase-icon"),
          tags$span(class = "armador-frase-label", "Estás por descargar: "),
          tags$span(class = "armador-frase-texto", txt)
        ),
        tags$div(
          class = "armador-frase-funnel",
          fila_funnel(
            bslib::tooltip(
              tags$span(class = "armador-frase-tip",
                        if (hay_periodo) "Muestra T0 del período" else "Muestra T0 (todos los períodos)"),
              "Personas encuestadas en el trimestre inicial (t0) del/los período(s) elegido(s). Es el 100% de referencia, antes del apareo con t1."
            ),
            fnum(tp$t0), "100%"
          ),
          fila_funnel(
            bslib::tooltip(
              tags$span(class = "armador-frase-tip", "Dúos apareados (el panel)"),
              "Personas reencontradas en t1: forman los dúos del panel. Las que no se reencuentran se pierden por atrición."
            ),
            fnum(tp$match),
            paste0(armador_fmt_pct(pct_match), " de la muestra T0")
          ),
          fila_funnel(
            "Con el resto de tus filtros",
            fnum(n_filt),
            paste0(armador_fmt_pct(pct_sel), " de la muestra T0"),
            final = TRUE
          )
        )
      )
    })

    ### Warning de muestra chica / subconjunto vacío. Estilado en www/style.css
    ### (.armador-warning). Sólo aparece cuando el subconjunto es vacío o chico.
    output$warning_n <- renderUI({
      n <- n_filas()
      if (n == 0) {
        tags$div(
          class = "armador-warning",
          icon("triangle-exclamation"),
          tags$span("Ningún registro cumple los filtros seleccionados. Ajustá la selección.")
        )
      } else if (n < ARMADOR_N_MIN) {
        tags$div(
          class = "armador-warning",
          icon("triangle-exclamation"),
          tags$span(sprintf(
            "Muestra chica (menos de %d filas): leé los resultados con cautela.",
            ARMADOR_N_MIN))
        )
      } else {
        NULL
      }
    })

    ### Preview: primeras 20 filas del subconjunto. head(20) |> collect() es
    ### barato (no materializa el panel entero). gt para no sumar dependencia
    ### (DT no está en el runtime); el contenedor scrollea horizontal en la UI.
    output$preview <- gt::render_gt({
      df <- panel_filtrado() |> head(20) |> dplyr::collect() |>
        armador_preparar_salida(etiquetar = identical(input$etiquetas, "si"))
      validate(need(nrow(df) > 0,
                    "Sin filas para previsualizar con los filtros actuales."))
      ### opt_interactive: columnas ordenables (clic en encabezado). Sin
      ### paginación (son 20 filas). Usa reactable por debajo.
      gt::gt(df) |>
        gt::opt_interactive(
          use_sorting      = TRUE,
          use_pagination   = FALSE,
          use_compact_mode = TRUE
        )
    })

    ### --- Descargas: collect() COMPLETO del subconjunto, sólo bajo demanda --
    ### Es el único punto donde se materializa el panel filtrado entero. El
    ### caso "sin filtros" equivale a la descarga del panel completo de la
    ### sección Datos actual (no regresiona).
    nombre_archivo <- function(ext) {
      ds  <- if (identical(input$dataset, "anual")) "interanual" else "intertrim"
      etq <- if (identical(input$etiquetas, "si")) "_etiquetado" else ""
      paste0("eph_panel_armado_", ds, etq, "_", format(Sys.Date(), "%Y%m%d"), ext)
    }

    ### Materializa el subconjunto filtrado y lo prepara para salida (etiquetado
    ### según el control + esquema _t0/_t1). Único punto con collect() completo.
    df_descarga <- function() {
      armador_preparar_salida(dplyr::collect(panel_filtrado()),
                              etiquetar = identical(input$etiquetas, "si"))
    }

    output$descarga_parquet <- downloadHandler(
      filename = function() nombre_archivo(".parquet"),
      content  = function(file) arrow::write_parquet(df_descarga(), file),
      contentType = "application/octet-stream"
    )

    output$descarga_csv <- downloadHandler(
      filename = function() nombre_archivo(".csv.gz"),
      content  = function(file) {
        ### readr auto-comprime cuando el path termina en .gz. El `file` que
        ### entrega downloadHandler es un temporal sin extensión, así que
        ### escribimos a un .csv.gz temporal y lo copiamos al destino.
        tmp <- tempfile(fileext = ".csv.gz")
        on.exit(unlink(tmp), add = TRUE)
        readr::write_csv(df_descarga(), tmp)
        file.copy(tmp, file, overwrite = TRUE)
      },
      contentType = "application/gzip"
    )

    ### Diccionario de variables (metadata estática, no depende de los filtros).
    ### columnas_panel_runtime es el tibble canónico definido en
    ### R/panel_descarga.R (sigue siendo la fuente del diccionario).
    output$descarga_diccionario <- downloadHandler(
      filename = function() {
        paste0("eph_panel_diccionario_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content  = function(file) readr::write_csv(armador_diccionario_salida(), file),
      contentType = "text/csv"
    )

    ### Contrato hacia la Fase 3 (integración al hub).
    list(
      query   = panel_filtrado,
      n_filas = n_filas,
      momento = reactive(if (identical(input$momento, "t1")) "t1" else "t0"),
      dataset = reactive(if (identical(input$dataset, "anual")) "anual" else "trimestral")
    )
  })
}
