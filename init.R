# init.R
#
# Lista de paquetes que la app necesita en runtime. Se instalan en la VM
# del workflow de GH Actions ANTES de que rsconnect haga el snapshot,
# para que `renv::dependencies()` los detecte y los incluya en el
# manifest del bundle subido a shinyapps.io.
#
# Si falta uno acá, el deploy termina en "success" pero la app arranca
# con "Error in loadNamespace(x) : there is no package called 'X'" y
# devuelve HTTP 500.
#
# Mantener esta lista sincronizada con: ETL/00-libraries.R (library()) +
# cualquier `pkg::fn()` referenciado en R/.

### Lista mínima necesaria. Reducida agresivamente para mantener el
### footprint de RAM bajo el límite del plan free de shinyapps.io.
### Removidos: ggplot2, gghighlight (solo en data_viz.R local), thematic,
### ragg, markdown, imola.
my_packages <- c(
  # core shiny + theming
  "shiny", "bslib", "bsicons", "brand.yml",
  # tidyverse mínimo
  "dplyr", "tidyr", "purrr", "stringr", "tibble", "glue",
  # io / formatos
  "arrow", "readr",
  # visualización
  "highcharter", "gt", "reactable",
  # utilidades shiny
  "waiter",
  # dominio EPH
  "eph",
  # etiquetado del dataset del Armador (organize_labels -> haven::as_factor)
  "haven"
)

install_if_missing <- function(p) {
  if (p %in% rownames(installed.packages()) == FALSE) {
    install.packages(p)
  }
}
invisible(sapply(my_packages, install_if_missing))
