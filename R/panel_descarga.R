### Panel "Datos" (issue #35).
###
### Expone el dataset principal del panel longitudinal en dos formatos
### (parquet + CSV gzip) y el diccionario de variables como CSV.
### Server-side: los downloadHandler() viven en app.R y leen los archivos
### de data_output/ directamente. No hay procesamiento en runtime.
###
### Tracking: cada botón dispara un evento GA4 'dataset_download' con
### {dataset, format} via onclick (el click burbujea al wrapper). Si gtag
### no está cargado (consent denegado, GA4_DISABLE), el evento se descarta.


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


### Helper: downloadButton con tracking GA4 client-side via onclick
### en el wrapper (el click burbujea, dispara el evento, sigue la descarga).
download_btn_tracked <- function(output_id,
                                 label,
                                 dataset,
                                 format,
                                 size_label,
                                 icon_name = "download") {
  onclick_js <- sprintf(
    "if(typeof gtag==='function'){gtag('event','dataset_download',{dataset:'%s',format:'%s'});}",
    dataset, format
  )
  tags$div(
    class = "descarga-btn-wrapper",
    onclick = onclick_js,
    shiny::downloadButton(
      output_id,
      label = paste0(label, "  (", size_label, ")"),
      icon  = shiny::icon(icon_name),
      class = "btn-descarga"
    )
  )
}


### Helper: item de dropdown que dispara una descarga vía downloadLink.
### shiny::downloadLink renderiza como <a href="session/.../download/...">,
### le sumamos class="dropdown-item" para tomar el estilo del menú Bootstrap
### y un onclick para tracking GA4.
download_dropdown_item <- function(output_id,
                                   label,
                                   dataset,
                                   format,
                                   size_label,
                                   icon_name) {
  onclick_js <- sprintf(
    "if(typeof gtag==='function'){gtag('event','dataset_download',{dataset:'%s',format:'%s'});}",
    dataset, format
  )
  tags$li(
    shiny::downloadLink(
      output_id,
      label = tagList(
        shiny::icon(icon_name),
        tags$span(label),
        tags$span(class = "dropdown-item-size", size_label)
      ),
      class = "dropdown-item",
      onclick = onclick_js
    )
  )
}


### Contenido de la sección Datos. Se expone como tagList para usarlo tanto
### dentro de un nav_panel (sidebar global viejo) como directo en la vista
### "datos" del patrón hub-and-spoke (issue #74).
panel_descarga_content <- tags$div(
  class = "panel-descarga",
  style = "max-width: 1100px;",

    ### Hero
    tags$div(
      class = "descarga-hero",
      tags$h2("Descargá el dataset", class = "descarga-hero-title"),
      tags$p(
        class = "descarga-hero-subtitle",
        "La app construye un panel longitudinal a partir del ",
        tags$strong("microdato de la EPH"), " para responder cuántas personas ",
        "permanecen, salen o entran a una condición laboral entre dos trimestres. ",
        "Podés bajar el panel armado para reutilizarlo en tus propios análisis."
      )
    ),

    ### Grid de tarjetas: dataset intertrim + dataset anual + diccionario.
    tags$div(
      class = "descarga-cards-grid",

      ### Tarjeta 1: Dataset intertrimestral (con dropdown de formatos)
      tags$div(
        class = "descarga-card",
        shiny::icon("database", class = "descarga-card-icon"),
        tags$h4("Panel longitudinal · intertrimestral",
                class = "descarga-card-title"),
        tags$p(class = "descarga-card-meta",
               "1.86 M filas · 31 columnas · dúos T → T+1"),
        tags$p(class = "descarga-card-desc",
               "Personas EPH vinculadas entre t0 y t1 trimestres ",
               "consecutivos. CSV viene en gzip; R, Python y ",
               "Stata 18+ lo leen directamente."),
        tags$div(
          class = "descarga-card-action dropdown",
          tags$button(
            class = "btn-descarga dropdown-toggle",
            type = "button",
            `data-bs-toggle` = "dropdown",
            `aria-expanded`  = "false",
            shiny::icon("download"),
            "Descargar"
          ),
          tags$ul(
            class = "dropdown-menu",
            download_dropdown_item(
              "descarga_panel_runtime_parquet",
              label      = "Parquet",
              dataset    = "panel_runtime", format = "parquet",
              size_label = "22 MB",
              icon_name  = "file-zipper"
            ),
            download_dropdown_item(
              "descarga_panel_runtime_csv",
              label      = "CSV (gzip)",
              dataset    = "panel_runtime", format = "csv_gz",
              size_label = "23 MB",
              icon_name  = "file-csv"
            )
          )
        )
      ),

      ### Tarjeta 2: Dataset interanual (issue #47)
      tags$div(
        class = "descarga-card",
        shiny::icon("calendar-week", class = "descarga-card-icon"),
        tags$h4("Panel longitudinal · interanual",
                class = "descarga-card-title"),
        tags$p(class = "descarga-card-meta",
               "1.41 M filas · 31 columnas · dúos T año X → T año X+1"),
        tags$p(class = "descarga-card-desc",
               "Personas EPH vinculadas con el mismo trimestre del ",
               "año siguiente. Útil para neutralizar la estacionalidad ",
               "y leer cambios estructurales anuales."),
        tags$div(
          class = "descarga-card-action dropdown",
          tags$button(
            class = "btn-descarga dropdown-toggle",
            type = "button",
            `data-bs-toggle` = "dropdown",
            `aria-expanded`  = "false",
            shiny::icon("download"),
            "Descargar"
          ),
          tags$ul(
            class = "dropdown-menu",
            download_dropdown_item(
              "descarga_panel_runtime_anual_parquet",
              label      = "Parquet",
              dataset    = "panel_runtime_anual", format = "parquet",
              size_label = "16 MB",
              icon_name  = "file-zipper"
            ),
            download_dropdown_item(
              "descarga_panel_runtime_anual_csv",
              label      = "CSV (gzip)",
              dataset    = "panel_runtime_anual", format = "csv_gz",
              size_label = "18 MB",
              icon_name  = "file-csv"
            )
          )
        )
      ),

      ### Tarjeta 3: Diccionario (botón directo)
      tags$div(
        class = "descarga-card",
        shiny::icon("book", class = "descarga-card-icon"),
        tags$h4("Diccionario de variables", class = "descarga-card-title"),
        tags$p(class = "descarga-card-meta",
               "31 variables · CSV"),
        tags$p(class = "descarga-card-desc",
               "Las 31 columnas del panel con su descripción. ",
               "Para más contexto sobre cada variable, ver ",
               tags$strong("Metadata > Glosario"), "."),
        tags$div(
          class = "descarga-card-action",
          download_btn_tracked(
            "descarga_diccionario_csv",
            label      = "Descargar CSV",
            dataset    = "diccionario", format = "csv",
            size_label = "3 KB",
            icon_name  = "download"
          )
        )
      )
    ),

    ### Aviso metodológico al pie (full width, treatment amber)
    tags$div(
      class = "descarga-aviso",
      tags$p(
        class = "descarga-aviso-title",
        shiny::icon("triangle-exclamation"),
        "Limitaciones metodológicas"
      ),
      tags$ul(
        tags$li(
          tags$strong("Intervención INDEC 2007-2015: "),
          "el propio organismo desestima estas series para el análisis ",
          "del mercado de trabajo. Considerá excluirlas o reportarlas con reservas."
        ),
        tags$li(
          tags$strong("Panel balanceado: "),
          "el dataset solo incluye personas presentes en t0 ",
          tags$em("y"), " en t1. Las personas que la EPH pierde entre ",
          "trimestres (atrición) quedan fuera."
        ),
        tags$li(
          tags$strong("Inconsistencias entre t0 y t1: "),
          "el flag ", tags$code("consistencia"), " marca casos donde ",
          "el algoritmo detectó variables estables (sexo, edad) que cambiaron ",
          "de forma imposible."
        ),
        tags$li(
          tags$strong("Cobertura: "),
          "el panel cubre desde 2003-T1 hasta el último trimestre publicado por INDEC."
        )
      ),
      tags$p(
        tags$strong("Fuente original: "),
        tags$a("INDEC · EPH",
               href   = "https://www.indec.gob.ar/indec/web/Institucional-Indec-BasesDeDatos",
               target = "_blank",
               style  = "color: #405BFF;"),
        " · Procesamiento con ",
        tags$a("{eph}", href = "https://docs.ropensci.org/eph/", target = "_blank",
               style = "color: #405BFF;"),
        ".",
        style = "margin-top: 0.75rem; color: #404040; margin-bottom: 0;"
      )
    )
  )


### Wrapper nav_panel para compatibilidad con el sidebar global viejo.
### El refactor a hub-and-spoke (issue #74) usa panel_descarga_content directo.
panel_descarga <- bslib::nav_panel(
  title = "Datos",
  icon  = bsicons::bs_icon("cloud-download"),
  panel_descarga_content
)