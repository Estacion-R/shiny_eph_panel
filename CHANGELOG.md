# Changelog

Todos los cambios notables de la app van acá.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.1.0/),
versionado [SemVer](https://semver.org/lang/es/) adaptado a app web:

- **MAJOR** (X.0.0): cambio estructural, nueva línea de análisis, breaking.
- **MINOR** (0.X.0): feature nueva visible al usuario.
- **PATCH** (0.0.X): fix, polish UX, mejora menor.

---

## [0.8.0] · 2026-05-03

### Added

- **Película + Tasas en modo Interanual** (#46 Fase 2). Las pestañas
  Película y Tasas de los 3 análisis (cond_act, cat_ocup, formalidad)
  ahora respetan el toggle Tipo de dúo. En modo Interanual leen los
  CSVs anuales pre-computados en lugar de mostrar el banner azul de
  "no soportado".
- 8 datasets nuevos en `data_output/` (paneles agregados + tasas
  históricas en formato anual):
  - `panel_cond_act_anual_historico.csv`
  - `panel_cat_ocup_anual_historico.csv`
  - `panel_formalidad_anual_historico.csv`
  - `panel_formalidad_ampliada_anual_historico.csv`
  - `tasas_cond_act_anual_historico.csv`
  - `tasas_cat_ocup_anual_historico.csv`
  - `tasas_formalidad_anual_historico.csv`
  - `tasas_formalidad_ampliada_anual_historico.csv`
- Nuevo script `ETL/11-build_historicos_anuales.R` que genera los
  8 CSVs anuales usando `regenerar_panel_historico(window = "anual")`
  y `build_tasas_historico(window = "anual")`.
- Selector "Trimestres" en sub-tab Tasas adapta sus choices al modo
  activo: `1-2 / 2-3 / 3-4 / 4-1` (intertrim) ↔ `T1 / T2 / T3 / T4`
  (anual).

### Changed

- `regenerar_panel_historico()` y `build_tasas_historico()` aceptan
  parámetro `window`. En anual usan dúos T_n año X → T_n año X+1
  (mismo trimestre) con label de período `"YYYY_tN"`.
- `01-extract.R` carga los 8 datasets anuales con cargas condicionales
  (fallback a tibble vacía).

### Removed

- Banner azul "Esta vista todavía no soporta Interanual" en pestañas
  Película y Tasas (ya no aplica, los datos están).

---

## [0.7.3] · 2026-05-03 · HOTFIX (continuación)

### Fixed

- **OOM al togglear a modo Interanual**. El v0.7.2 evitaba el OOM al
  boot pero seguía rompiendo cuando el usuario cambiaba a Interanual.
  Cada llamada a `armo_base_panel(window = "anual")` desde un módulo
  hacía `arrow::read_parquet(path, as_data_frame = FALSE)` que carga
  el parquet entero (~16 MB) como Arrow Table en memoria. En Foto hay
  3-5 llamadas en cascada (sankey + matriz + 3 tasas + delta año
  anterior), sumando ~80 MB que arrow no liberaba a tiempo.
- **Reemplazado por `arrow::open_dataset()`**, que es realmente lazy:
  solo lee el footer del parquet + los row groups que matchean al
  filter. Footprint mínimo y predictible a través de múltiples
  llamadas.
- Mismo cambio aplicado a `01-extract.R` para los metadatos del panel
  anual al boot.

---

## [0.7.2] · 2026-05-03 · HOTFIX

### Fixed

- **OOM en producción**: `panel_runtime_anual.parquet` ya no se carga
  como Arrow Table al boot (en `ETL/01-extract.R`). Mantener dos
  Tables abiertas simultáneamente excedía el budget de RAM del free
  tier de shinyapps.io y disparaba `oom (out of memory)` justo
  después de cargar bslib.
- En modo Interanual, `armo_base_panel()` ahora abre el parquet
  on-demand con filter pushdown y lo cierra cada llamada. Cuesta un
  poco más de I/O por refresh (lectura de 16 MB) pero el footprint
  de RAM al boot vuelve al nivel intertrim solo.
- Al boot, los metadatos del panel anual (`periodos_disponibles_anual`,
  `anios_disponibles_anual`) se derivan abriendo el parquet
  temporalmente con `col_select` solo de las 4 columnas necesarias y
  llamando `gc()` después.

---

## [0.7.1] · 2026-05-03

### Changed

- Pipeline mensual `update_eph_data.yml` ahora regenera
  automáticamente los parquets runtime (intertrim + anual) cuando
  hay un trimestre nuevo. Antes había que regenerarlos manualmente,
  con riesgo de drift entre los CSVs históricos (auto) y los
  parquets runtime (manuales). (#48)
- `ETL/09-build_paneles_runtime.R` carga el microdato directamente
  en lugar de depender de `01-extract.R` (que en runtime no lo
  carga). Mismo patrón que `ETL/09b-build_paneles_runtime_anual.R`.
- `add-paths` del PR auto incluye ahora todos los CSVs históricos +
  los 4 parquets/csv.gz de runtime.

---

## [0.7.0] · 2026-05-03

### Added

- Toggle **Tipo de dúo** en el FAB: alterna entre análisis
  intertrimestral (T → T+1, default) e interanual (T año X → T año X+1).
  La pestaña **Foto** de los 3 análisis (cond_act, cat_ocup, formalidad)
  recalcula sobre el panel anual cuando se elige Interanual. (#44 Fase 1)
- Nuevo dataset `data_output/panel_runtime_anual.parquet` (16 MB) +
  `panel_runtime_anual.csv.gz` (18 MB) generado por
  `ETL/09b-build_paneles_runtime_anual.R`.
- Banner azul de aviso "Esta vista todavía no soporta Interanual" en
  pestañas Película y Tasas mientras se completa la Fase 2 / Fase 3
  (issues #46, #47).
- Helper `alerta_modo_anual_no_soportado()` en `R/utils_analisis.R`.
- Selectores de año y dúo se adaptan automáticamente al modo activo:
  - En anual el dúo cambia formato `1-2 / 2-3 / 3-4 / 4-1` →
    `T1 / T2 / T3 / T4`.
  - El selector de año se limita a años con dúo anual válido (sin el
    último año de la serie cuando todavía no hay t+1).

### Fixed

- `armo_tabla_sankey()` ahora es defensivo cuando recibe tabla vacía
  (devuelve schema vacío en lugar de tirar error en el `if`).
- `output$sankey` en los 3 módulos suma `req(nrow(panel) > 0)` para
  pausar el render durante transiciones del toggle sin romper.

---

## [0.6.0] · 2026-05-02

Primer release con CHANGELOG. Versiones anteriores no están documentadas
acá; ver historial de issues cerrados y `git log` para detalle.

### Added

- Sección **Datos** en el sidebar con descarga del panel longitudinal
  completo en Parquet y CSV (gzip), diccionario de variables descargable y
  aviso de limitaciones metodológicas. (#35)
- Generación de `data_output/panel_runtime.csv.gz` integrada al pipeline
  ETL de actualización mensual.
- Versionado de la app: `R/version.R`, `CHANGELOG.md` y versión visible en
  el footer del sidebar.
- Record de cambios a comunicar en `comunicaciones/cambios_a_comunicar.md`
  para alimentar contenido de redes sociales.

### Fixed

- Eje Y del line chart se recalcula al togglear series via legend
  interactiva. (#32)
- Eje X del line chart mostraba `[o,[o,...` por nested categories sin el
  plugin `grouped-categories`. Reemplazado por categorías planas + plot
  bands fantasma con label de año debajo del eje. (#40)

### Changed

- Cache-busting automático de assets estáticos (`style.css`, `script.js`,
  `highlight.min.js`): el `href` ahora incluye `?v=<mtime>` y el browser
  invalida cache cuando el archivo cambia.
