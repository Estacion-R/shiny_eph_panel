### Paneles estáticos de la sección Metadata (issue #31).
###   - panel_glosario: tabla de variables EPH usadas en la app.
###   - panel_definiciones: conceptos metodológicos del análisis longitudinal.
###
### Si crece el contenido, evaluar moverlo a archivos .qmd/.md y cargarlos
### con `includeMarkdown()`. Por ahora el HTML inline alcanza.


### Tabla de variables EPH con etiqueta, descripción y valores. Pasada a gt
### para mantener la estética del resto de la app.
glosario_vars <- tibble::tribble(
  ~Variable,    ~Etiqueta,                  ~Descripción,                                                                                          ~`Valores posibles`,
  "ESTADO",     "Condición de actividad",   "Situación de la persona respecto al mercado laboral.",                                                "1=Ocupado · 2=Desocupado · 3=Inactivo · 4=Menor de 10 años",
  "CAT_OCUP",   "Categoría ocupacional",    "Modalidad bajo la cual la persona ocupada se inserta en el mercado de trabajo.",                      "1=Patrón · 2=Cuenta propia · 3=Asalariado · 4=Trab. familiar sin remun.",
  "PP07H",      "Descuento jubilatorio",    "Indica si al asalariado le hacen aportes jubilatorios. Variable clave para la formalidad clásica.",   "1=Sí · 2=No",
  "PP07I",      "Aporte propio asalariado", "Indica si el asalariado realiza aportes por sí mismo cuando el empleador no se los descuenta.",       "1=Sí · 2=No",
  "PP07J",      "Beneficios laborales",     "Indica si el asalariado tiene vacaciones pagas, aguinaldo o días por enfermedad.",                    "1=Sí · 2=No",
  "PP07K",      "Recibo de sueldo",         "Indica si el asalariado recibe recibo de sueldo o equivalente.",                                       "1=Sí · 2=No",
  "PP05I",      "Monotributo (cta. propia)", "Indica si el cuenta propia paga monotributo. Disponible desde 2023-T4.",                              "1=Sí · 2=No",
  "PP05K",      "Aportes propios cta. propia", "Indica si el cuenta propia hace aportes jubilatorios. Disponible desde 2023-T4.",                   "1=Sí · 2=No",
  "CH04",       "Sexo",                     "Sexo declarado por la persona.",                                                                       "1=Varón · 2=Mujer",
  "CH06",       "Edad",                     "Edad en años cumplidos al momento de la encuesta.",                                                    "0-99",
  "AGLOMERADO", "Aglomerado urbano",        "Aglomerado urbano relevado por la EPH (31 aglomerados).",                                              "Códigos INDEC (ej. 32 = CABA)",
  "PONDERA",    "Ponderador general",       "Factor de expansión para estimar totales a partir de la muestra.",                                     "Numérico",
  "CODUSU",     "ID de vivienda",           "Identificador único de la vivienda. Clave de panel junto con NRO_HOGAR y COMPONENTE.",                 "Carácter",
  "NRO_HOGAR",  "Nº de hogar",              "Número de hogar dentro de la vivienda. Parte de la clave de panel.",                                   "Numérico",
  "COMPONENTE", "Nº de persona",            "Número de persona dentro del hogar. Parte de la clave de panel.",                                      "Numérico"
)

panel_glosario <- bslib::nav_panel(
  title = "Glosario",
  icon = icon("book-open"),
  card(
    h2("Glosario de variables EPH", class = "hero-title"),
    p(
      "Resumen de las variables del microdato de la EPH-INDEC utilizadas en esta aplicación. ",
      "Definiciones extraídas del ",
      tags$a("Diseño de Registro y Estructura de Bases de la EPH",
             href = "https://www.indec.gob.ar/ftp/cuadros/menusuperior/eph/EPH_registro_4t_2023.pdf",
             target = "_blank"),
      " (INDEC)."
    ),
    br(),
    gt::gt_output("metadata_glosario_table"),
    br(),
    p(em("Nota:"), "PP05I y PP05K se introdujeron en el cuestionario a partir del 4° trimestre de 2023, por lo que la definición ampliada de informalidad (que las usa) sólo está disponible desde esa fecha en adelante.")
  )
)


panel_definiciones <- bslib::nav_panel(
  title = "Definiciones",
  icon = icon("list-ul"),
  card(
    h2("Definiciones metodológicas", class = "hero-title"),
    p("Conceptos clave para interpretar los indicadores de esta aplicación."),
    br(),

    h4("Esquema de rotación 2-2-2"),
    p(
      "La EPH selecciona viviendas que participan del operativo durante ",
      strong("dos"), " trimestres consecutivos, descansan ",
      strong("dos"), " trimestres y vuelven a entrevistarse otros ",
      strong("dos"), " trimestres más, antes de salir definitivamente de la muestra. ",
      "Este diseño permite seguir a las mismas personas en el tiempo y construir paneles longitudinales."
    ),
    br(),

    h4("Dúo / panel"),
    p(
      "Un ", strong("dúo"), " es el par de trimestres consecutivos en los que una misma vivienda fue entrevistada (por ejemplo, T1-T2 de un año o T4-T1 entre dos años). ",
      "Un ", strong("panel"), " es el subconjunto de personas presentes en ambos trimestres del dúo, sobre las cuales se computan las transiciones."
    ),
    br(),

    h4("Tasa de Persistencia"),
    p(
      "Porcentaje de personas en una categoría en el trimestre inicial (t0) que ",
      strong("siguen"), " en la misma categoría en el trimestre siguiente (t1). ",
      em("Ejemplo: % de Asalariados en t0 que siguen siendo Asalariados en t1.")
    ),

    h4("Tasa de Salida"),
    p(
      "Porcentaje de personas en una categoría en t0 que ", strong("ya no están"), " en esa categoría en t1. ",
      "Es complemento de la persistencia: Salida = 100 - Persistencia."
    ),

    h4("Tasa de Entrada"),
    p(
      "Porcentaje de personas en una categoría en t1 que ", strong("no estaban"), " en esa categoría en t0 (vinieron desde otra). ",
      em("Ejemplo: % de Ocupados en t1 que en t0 estaban Desocupados o Inactivos.")
    ),
    br(),

    h4("Análisis transversal vs. longitudinal"),
    p(
      strong("Transversal: "), "lectura tipo 'foto'. Caracteriza a la población en un momento puntual (un trimestre)."
    ),
    p(
      strong("Longitudinal (panel): "), "lectura tipo 'película'. Sigue a las mismas personas en dos momentos del tiempo y mide cambios individuales."
    ),
    br(),

    h4("Intervención del INDEC (2007-2015)"),
    p(
      "Entre enero de 2007 y diciembre de 2015 el INDEC fue intervenido. ",
      "El propio organismo recomendó leer las series del período ",
      tags$a("con reservas",
             href = "https://www.indec.gob.ar/ftp/cuadros/sociedad/anexo_informe_eph_23_08_16.pdf",
             target = "_blank"),
      " (decretos 181/15 y 55/16). En esta app la banda gris en los gráficos marca ese período. ",
      "El checkbox ", em("'Excluir período de intervención INDEC'"), " permite filtrarlo cuando se necesita comparar sólo con datos validados oficialmente."
    ),
    br(),

    h4("Definiciones de informalidad"),
    p(
      strong("Clásica (asalariados): "), "informal si NO le hacen descuento jubilatorio (PP07H = 2). Disponible para toda la serie 2003-actualidad. Solo aplica a asalariados."
    ),
    p(
      strong("Ampliada (OIT 2023): "), "extiende el universo a cuenta propia, donde se considera formal si paga monotributo o realiza aportes propios. Disponible desde 2023-T4 (cuando aparecen PP05I/K en el cuestionario)."
    ),
    br(),

    h4("Limitaciones del panel EPH"),
    tags$ul(
      tags$li(strong("Atrición: "), "no todas las personas presentes en t0 pueden ser re-entrevistadas en t1 (mudanzas, no respuesta). El panel real es < 50%."),
      tags$li(strong("Representatividad: "), "el subset balanceado del panel pierde algo de representatividad estricta del universo. Las inferencias deben tomarse como aproximadas."),
      tags$li(strong("Cambios metodológicos: "), "la EPH cambió variables y formularios varias veces (2003 reformulación, 2016 cambio de aglomerados, 2023 nuevas vars de formalidad). Las series largas requieren contexto.")
    )
  )
)
