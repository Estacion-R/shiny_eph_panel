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

my_packages <- c(
  # core shiny + theming
  "shiny", "bslib", "bsicons", "brand.yml", "thematic",
  # tidyverse
  "dplyr", "tidyr", "purrr", "stringr", "tibble", "glue",
  # io / formatos
  "arrow", "markdown",
  # visualización
  "highcharter", "gghighlight", "ragg", "gt",
  # utilidades shiny (imola removido: archivado en CRAN y no se usaba)
  "waiter",
  # dominio EPH
  "eph"
)

install_if_missing <- function(p) {
  if (p %in% rownames(installed.packages()) == FALSE) {
    install.packages(p)
  }
}
invisible(sapply(my_packages, install_if_missing))
