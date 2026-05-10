# Estado · shiny_eph_panel

> Última actualización: 2026-05-09

## Live

- **App productiva:** https://estacionr.shinyapps.io/shiny_eph_panel/
- **App staging:** https://estacionr.shinyapps.io/shiny_eph_panel_staging/
- **Repo:** https://github.com/Estacion-R/shiny_eph_panel
- **Versión actual:** v0.9.0 + Sprint Testing + Sprint B (deployadas
  al merge de PR #70 el 2026-05-09).
- **Datos hasta:** 2025-T4 (próxima publicación INDEC esperada
  agosto/septiembre 2026).

## Secciones de la app

| Sección | Estado |
|---|---|
| Inicio (landing) | OK |
| Análisis de panel · Condición de actividad | OK (toggle Interanual) |
| Análisis de panel · Categoría ocupacional | OK (toggle Interanual) |
| Análisis de panel · Formal / Informal (clásica + ampliada) | OK (toggle Interanual) |
| Análisis de panel · **Calidad de la muestra** | OK (toggle Interanual) |
| Análisis de panel · **Datos descargables** | OK (Parquet/CSV gzip, intertrim + anual) |
| Análisis transversal · Indicadores básicos | Próximamente (placeholder) |
| Análisis transversal · Calidad del empleo | Próximamente (placeholder) |
| Metadata · Glosario + Definiciones + links | OK |

## Pipeline automático

| Componente | Cuándo | Hace |
|---|---|---|
| `update_eph_data.yml` | Día 5 cada mes, 12 UTC | Detecta nuevos trimestres → regenera CSVs + parquets runtime → **valida con `ETL/12-validate_paneles_runtime.R`** → PR auto-merge → deploy |
| `deploy_shinyapps.yml` | On-push a master con paths relevantes | Deploy directo a producción |
| `deploy_shinyapps_staging.yml` | On-push a staging con paths relevantes | Deploy directo a staging |
| `tests-unit.yml` | Cada PR + push a master/staging | Corre 185 tests testthat (funciones puras + server logic) |
| `tests-e2e.yml` | `workflow_dispatch` + cron domingo 06:00 UTC | Corre 7 expects E2E con `shinytest2` (no en cada PR para no inflar el ciclo) |
| Routine `trig_01Y3TmHxhCjecnGg8qRmNFac` | Día 7 cada mes, 14 ART | Audita el ciclo y reporta |
| Routine health check mensual | Día 1 cada mes | Genera reporte de salud y abre PR |

## Datos pre-procesados (cargados al iniciar la app)

| Archivo | Tamaño | Generado por |
|---|---|---|
| `panel_runtime.parquet` (intertrim) | 22 MB | `ETL/09-build_paneles_runtime.R` |
| `panel_runtime_anual.parquet` (anual) | 16 MB | `ETL/09b-build_paneles_runtime_anual.R` |
| `panel_cond_act_historico.csv` + variante `_anual` | ~80 paneles × N categorías | `ETL/04-build_panel_cond_act.R` |
| `panel_cat_ocup_historico.csv` + variante `_anual` | ídem | `ETL/05-build_panel_cat_ocup.R` |
| `panel_formalidad_historico.csv` + variante `_anual` | ídem | `ETL/06-build_panel_formalidad.R` |
| `panel_formalidad_ampliada_historico.csv` + variante `_anual` | desde 2023-T4 | `ETL/07-build_panel_formalidad_ampliada.R` |
| `tasas_*_historico.csv` × 4 (intertrim + anual) | tasas Persistencia/Salida/Entrada | `ETL/08-build_tasas_historico.R` |
| `calidad_panel_pct_historico.csv` + variante `_anual` | 83 dúos | `ETL/10-build_calidad_panel.R` |
| `df_tasas_mt.parquet` | tasas mercado de trabajo | `03-update_data.R` |

## Cobertura de tests

| Capa | Cantidad | Cuándo corre |
|---|---|---|
| Funciones puras (testthat) | 149 | `tests-unit.yml` en cada PR |
| Server logic (`shiny::testServer`) | +36 (185 total) | `tests-unit.yml` en cada PR |
| E2E (`shinytest2` + Chromote) | +7 expects (192 total con `RUN_E2E=true`) | `tests-e2e.yml` (manual + cron semanal) |

Detalle por archivo en `tests/testthat/`. Pirámide cerrada en
Sprint Testing (#61) durante 2026-05-04 a 2026-05-07.

## Issues abiertos relevantes

- **#5** Chatbot ellmer + Gemini — backlog wishlist, sin priorizar.
- **#12** Refactor a `mod_analisis()` genérico — pre-requisito para
  #29 y #30. Próximo Sprint C.
- **#13** Formal/Informal "tiene descuento jubilatorio" — bloqueado
  por 5 preguntas metodológicas. Sprint D cuando haya tiempo.
- **#29** Filtros sociodemográficos — Sprint E. Bloqueado por #12.
- **#30** Pobreza/indigencia — Sprint E dedicado. Bloqueado por #12.
- **#37** Tratamiento de paneles inconsistentes en cálculo de tasas
  — pendiente decisión metodológica (parcial: ya se mide y muestra
  el % en Calidad).
- **#39** Revisión integral (parcial cerrada con scope acotado) —
  diferido a otro sprint: CSS muerto, perf con profvis,
  accesibilidad, deps no usadas.
- **#42** Migrar Glosario/Definiciones a `.md`/`.qmd` — solo cuando
  crezca el contenido.
- **#43** Extender glosario con variables nuevas — convención: aplicar
  al cerrar features con vars nuevas (#29, #30).

> Nota: issues #44, #45, #46, #47, #48 y #61 ya shippeadas en master
> pero quedaron OPEN en GitHub. Cerrarlas a mano en próxima sesión
> de mantenimiento.

## Issues cerrados recientemente (cronológico)

- **#48** Pipeline mensual auto-regenera parquets runtime
  (2026-05-04, Sprint A · v0.9.0).
- **#46** Película + Tasas en modo Interanual (2026-05-04, Sprint A · v0.9.0).
- **#47** Calidad + Datos descargables en modo Interanual
  (2026-05-04, Sprint A · v0.9.0).
- **#61** Setup testing automatizado (2026-05-07, Sprint Testing).
- **#45** Validación ETL paneles intertrim + anual (2026-05-08,
  Sprint B). Gate en `update_eph_data.yml`.
- **#39** Pasada de anti-patterns dplyr/purrr (2026-05-09, Sprint B,
  scope acotado).
- **#37** Calidad: % de paneles con inconsistencias entre t0 y t1
  (2026-05-01).
- **#36** Calidad: histórico de % personas-panel encontradas
  (2026-05-01).

## Pendientes técnicos menores

- Comentario obsoleto en `ETL/09-build_paneles_runtime.R:24` dice
  "carga df_eph_full" pero `01-extract.R` ya no lo carga (el script 09
  hace su propio `arrow::read_parquet`). No bloquea, solo confunde.
- `ETL/10-build_calidad_panel.R` no está en `.rscignore`. Va al bundle
  pero no se ejecuta en runtime; consistente con 05-09 que tampoco
  están excluidos. Costo despreciable.
- Verificar si staging GA4 ID contamina métricas de prod (ambas
  branches comparten `G-NQPB4BHWMM` desde el fix del 2026-05-08).

## Comunicaciones y lanzamiento

| Material | Ubicación | Estado |
|---|---|---|
| Post 1° de mayo (Día del Trabajador) | `comunicaciones/2026-05-01_post_dia_trabajador.md` | Pendiente publicación |
| Post novedades mayo (v0.9.0 + descargas) | `comunicaciones/2026-05-04_post_novedades_mayo.md` | Pendiente publicación |
| Cambios a comunicar (registro vivo) | `comunicaciones/cambios_a_comunicar.md` | En uso |
| Artículo blog técnico (panel + EPH) | Web/Blog (pendiente) | En progreso |

## Próximos pasos sugeridos

- **Sprint C** · Refactor a `mod_analisis()` genérico (#12). Habilita
  #29 (filtros sociodemo) y #30 (pobreza/indigencia) sin triplicar
  cambios.
- **Sprint D** · Decisión metodológica formal/informal (#13). Sesión
  enfocada cuando haya tiempo de revisar las 5 preguntas pendientes.
- Revisar GA4 después de ~1.5 meses de tracking productivo para guiar
  optimizaciones con datos reales.
- Cerrar issues #44, #45, #46, #47, #48, #61 en GitHub (housekeeping).
