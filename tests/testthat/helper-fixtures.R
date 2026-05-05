### Helpers para cargar fixtures sintéticos.
### Se ejecuta automáticamente antes de cada test (testthat carga todos
### los archivos `helper-*.R` del directorio).
###
### Convención: las fixtures viven en tests/testthat/fixtures/ y se
### generan con tests/testthat/fixtures/_generar_fixtures.R una sola
### vez. NO se versionan los pasos de generación, solo los .rds resultantes.

### Path al directorio de fixtures (relativo a tests/testthat/, donde
### corre el test session).
fixtures_dir <- function() {
  testthat::test_path("fixtures")
}

### Carga el panel mock sintético. 100 individuos × 3 ondas trimestrales
### (2024-T1, 2024-T2, 2024-T3) con CODUSU/NRO_HOGAR/COMPONENTE
### controlados para que los paneles encadenen.
###
### Schema: equivale a un microdato EPH reducido (ANO4, TRIMESTRE,
### CODUSU, NRO_HOGAR, COMPONENTE, CH04, CH06, ESTADO, CAT_OCUP,
### PP07H, PP05I, PP05K, PONDERA).
load_panel_mock <- function() {
  readRDS(file.path(fixtures_dir(), "panel_mock.rds"))
}
