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

### Cargar funciones del proyecto. NO sourcear 01-extract.R porque
### levantar todos los datasets lleva tiempo y los tests deberían
### ser rápidos. Cada test que necesite datos usa los fixtures
### sintéticos (tests/testthat/fixtures/).
source("ETL/00-libraries.R")
source("ETL/99-functions.R")
source("R/utils_analisis.R")

testthat::test_dir("tests/testthat")
