### Runner principal de testthat (issue #61).
###
### Para correr la suite localmente:
###   Rscript tests/testthat.R
###
### O desde una sesión interactiva:
###   testthat::test_dir("tests/testthat")
###
### CI: GitHub Actions corre este script en cada push (ver
### .github/workflows/tests-unit.yml).

library(testthat)

### Cargar SOLO los paquetes mínimos necesarios para los tests de
### funciones puras. NO source-amos `ETL/00-libraries.R` (que carga
### highcharter, gt, waiter, bsicons, brand.yml — UI-only) ni
### `01-extract.R` (que levanta los datasets reales).
###
### Los tests de funciones que dependen de Shiny (testServer) se
### moverán a su propio runner cuando arranque Sprint test-2.
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(eph)        # organize_panels usado por armo_base_panel modo legacy
  library(arrow)      # read_parquet en armo_base_panel modo runtime
  library(glue)
})

### Definir funciones del proyecto. source() solo define funciones;
### no se ejecutan llamadas que requieran highcharter/gt/etc. hasta
### que un test las invoque (y por ahora ningún test del Sprint
### test-1 las invoca).
source("ETL/99-functions.R")
source("R/utils_analisis.R")

testthat::test_dir("tests/testthat")
