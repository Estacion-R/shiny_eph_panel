# Changelog

Todos los cambios notables de la app van acá.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.1.0/),
versionado [SemVer](https://semver.org/lang/es/) adaptado a app web:

- **MAJOR** (X.0.0): cambio estructural, nueva línea de análisis, breaking.
- **MINOR** (0.X.0): feature nueva visible al usuario.
- **PATCH** (0.0.X): fix, polish UX, mejora menor.

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
