# Estado · shiny_eph_panel

> Última actualización: 2026-08-07 (Auditoría de estado tras 2 meses de pausa. App prod y staging OK · **pipeline de datos ROTO**: INDEC publicó 2026-T1 y `update_eph_data.yml` falló el 2026-08-05 por paquetes R faltantes en CI · Tests E2E rotos desde 2026-06-07 por la misma causa. Plan de trabajo vigente abajo.)

## Live

- **App productiva:** https://estacionr.shinyapps.io/shiny_eph_panel/
- **App staging:** https://estacionr.shinyapps.io/shiny_eph_panel_staging/
- **Repo:** https://github.com/Estacion-R/shiny_eph_panel
- **Versión actual:** v0.9.1-dev (staging)
  - v0.9.0: Sprint Testing + Sprint B + Sprint C (refactor `mod_analisis()`) + rediseño UX hub-and-spoke deployeado a prod (PR #74 mergeada, commits `d9cd0fc` + `4f60c5c`, 2026-05-14, HTTP 200)
  - v0.9.1-dev (staging): Armador de panel #77 F1-F5 (módulo mod_armador.R, preview gt, descarga Parquet/CSV, hub integration) + Aglomerado #78 (re-bootstrap microdato, 32 cols, parquets regenerados) + suite de tests (50 unit + 2 e2e, 315 PASS, CI verde), deployeado a staging 2026-05-24
- **Datos hasta:** 2025-T4 en producción. **INDEC ya publicó 2026-T1**
  (verificado 2026-08-07: `EPH_usu_1_Trim_2026_txt.zip`, HTTP 200, 3,5 MB).
  Pendiente de incorporar: el pipeline lo descargó bien el 2026-08-05 pero
  falló antes de crear el PR. 2026-T2 todavía no está publicado.

## Plan de trabajo · 2026-08-07

### Fase 1 · Desbloquear el pipeline de datos (CRÍTICO)

Causa raíz: `ETL/09-build_paneles_runtime.R` hace `source("ETL/00-libraries.R")`,
que carga el stack completo de la app (13 paquetes), pero los workflows de CI
instalan un subconjunto. Nunca se detectó porque el step tiene
`if: has_new == 'true'` y hasta agosto nunca hubo trimestres nuevos.

| # | Tarea | Estado |
|---|---|---|
| 1.1 | `update_eph_data.yml`: agregar 9 paquetes faltantes (`shiny`, `highcharter`, `bslib`, `brand.yml`, `bsicons`, `waiter`, `tidyr`, `gt`, `reactable`) | Pendiente |
| 1.2 | `tests-e2e.yml`: agregar `brand.yml` y `reactable` (roto desde 2026-06-07, 9 fallas seguidas) | Pendiente |
| 1.3 | PR a staging, verificar CI verde | Pendiente |
| 1.4 | `workflow_dispatch` de `update_eph_data.yml` para incorporar 2026-T1 | Pendiente |
| 1.5 | Validar parquets + deploy a prod (requiere confirmación de Pablo) | Pendiente |

### Fase 2 · Housekeeping acumulado

| # | Tarea | Estado |
|---|---|---|
| 2.1 | Mergear PRs de health check #85 (jun), #90 (jul), #91 (ago) · las 3 MERGEABLE, solo agregan un `.md` | Pendiente |
| 2.2 | Cerrar #87 (resuelto en PR #88/#89 el 2026-06-20, sigue abierto) | Pendiente |
| 2.3 | Borrar `data_raw/df_eph.parquet.bak` (40 MB) y `.bak2` (39 MB), gitignored | Pendiente |
| 2.4 | Commitear docs pendientes (BACKLOG, ESTADO, comunicaciones) sin commitear desde mayo | Pendiente |

### Fase 3 · Comunicación

| # | Tarea | Estado |
|---|---|---|
| 3.1 | Registrar la incorporación de 2026-T1 en `comunicaciones/cambios_a_comunicar.md` | Pendiente |
| 3.2 | Publicar drafts pendientes (novedades mayo, armador, hub-and-spoke) | Pendiente |

### Fase 4 · Deuda técnica (backlog, no en esta sesión)

- **Refactor `ETL/09` y `09b`**: que carguen solo `dplyr` + `arrow` en vez de
  todo `00-libraries.R`. Es la causa estructural del fallo de Fase 1; el fix
  de 1.1 es el parche seguro para desbloquear el dato ya.
- Crear issue dedicado de a11y Highcharts (highcharter 0.9.5).
- Resto de #39: auditoría `renv::status`, Lighthouse/axe, fonts duplicadas.
- Sprint E: #29 (filtros sociodemográficos) y #30 (pobreza/indigencia).

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

## Issues cerrados recientemente (2026-05-28)

- **#79** Refactor de rendimiento (núcleo): **COMPLETADO EN PROD (2026-05-28)**
  Implementación: `periodo_duo()`, `df_eph_panel()`, `tasas()`, `tasas_anio_ant()` y `delta_label()` pasados a reactives a nivel módulo en `mod_analisis.R`. Outputs convertidos a renders normales. Observe contenedor eliminado. `outputOptions(suspendWhenHidden=FALSE)` directo (sin `onFlushed`). Test blindaje: `testServer` con contador de `armo_base_panel` memoización. PR #81 (staging) + PR #82 (master), deploy HTTP 200, staging resincronizado. Sustituye al profvis con métrica reproducible.

- **#39** Código muerto + housekeeping: **COMPLETADO EN PROD (2026-05-28)**
  Borrados 3 helpers muertos de `panel_seccion.R`, 4 objetos muertos de `panel_descarga.R` (conservando `columnas_panel_runtime`), reglas CSS huérfanas (filter-rail + tarjetas/dropdown/aviso de la vista Datos vieja) y `www/script.js` completo. ~500 líneas menos. Bundle: `.rscignore` ahora excluye scripts ETL de build (04-12, 04b, 09b, _bootstrap_aglomerado). PR #83 (staging) + PR #84 (master), deploy HTTP 200, staging resincronizado. Pendientes: resto de #39 (auditoría renv::status, Lighthouse/axe, fonts duplicadas).

- **a11y Highcharts (intento + revert):** **REVERTIDO (2026-05-28)**
  Helper `hc_a11y()` aplicado a 6 charts (Sankey Foto + sankey_a/b + tasas_chart + line + 2 calidad). Debug con chromote sobre `saveWidget(selfcontained=TRUE)` mostró que `chart.accessibility` queda FALSE y 0 regiones de screen-reader generadas. Causa: `modules/accessibility.js` carga DESPUÉS del highchart-binding, así que el módulo no se engancha. Revert completo (5 archivos). Hallazgo documentado en MEMORY.md.

## Issues abiertos relevantes

- **#77** Armador de panel (MVP, 4 filtros): **COMPLETADO EN PROD (2026-05-28, v0.9.1)**
  Implementación end-to-end F1-F5: módulo R/mod_armador.R, preview gt interactivo, descarga Parquet/CSV con/sin etiquetas, integración al hub (tarjeta "Armá tu panel"), retiro de "Datos descargables", descriptores con lenguaje natural, tests 50 unit + 2 e2e, deploy CI verde. **Cerrado automáticamente con PR #80.**

- **#78** Armador · filtro Aglomerado (fast-follow): **COMPLETADO EN PROD (2026-05-28, v0.9.1)**
  Re-bootstrap del microdato por JOIN de 86 trimestres INDEC (0% NA), parquets regenerados a 32 cols, filtro multi-select código→nombre. **Cerrado automáticamente con PR #80.**
- **#5** Chatbot ellmer + Gemini, backlog wishlist, sin priorizar.
- **#13** Formal/Informal "tiene descuento jubilatorio", bloqueado
  por 5 preguntas metodológicas. Sprint D cuando haya tiempo.
- **#29** Filtros sociodemográficos, Sprint E. Desbloqueado tras el
  cierre efectivo de #12.
- **#30** Pobreza/indigencia, Sprint E dedicado. Desbloqueado tras
  el cierre efectivo de #12.
- **#37** Tratamiento de paneles inconsistentes en cálculo de tasas,
  pendiente decisión metodológica (parcial: ya se mide y muestra
  el % en Calidad).
- **#79** Revisión integral: refactor reactives anidados (profvis) + a11y gráficos Highcharts + fieldset/legend + código muerto (#39). **Núcleo de rendimiento CERRADO (2026-05-28). a11y diferido a issue dedicado. fieldset/legend y resto de #39 en próximas semanas.**
- **#42** Migrar Glosario/Definiciones a `.md`/`.qmd`, solo cuando
  crezca el contenido.
- **#43** Extender glosario con variables nuevas, convención: aplicar
  al cerrar features con vars nuevas (#29, #30).
- **#75** UX: usar `{cookies}` para persistir preferencias del usuario
  entre sesiones. Prioridad baja. Detalle en `BACKLOG.md`.

> Nota: issues #12, #44, #45, #46, #47, #48 y #61 ya shippeadas en
> master se cerraron el 2026-05-18 con comentario referenciando sprint/PR.
> El #76 (duplicado de #75) se cerró el 2026-05-16.

## Versiones en producción

- **v0.9.1** (2026-05-28, master e06e249): Issue #79 núcleo rendimiento (refactor reactives en mod_analisis + test blindaje) + Issue #39 cleanup (~500 líneas código muerto + bundle exclusion) COMPLETADOS. a11y Highcharts revertido, documentado en MEMORY.md. Staging alineado.
- **v0.9.0+** (2026-05-17, PR #74 mergeada): Rediseño UX hub-and-spoke (landing 4 tarjetas, sidebar interno, URL state, toggle Tipo dúo). Deployeado a prod HTTP 200. Posts de redes con 6 screenshots en `comunicaciones/assets/2026-05-14_hub-and-spoke/`.
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

- **GA4 staging contamina prod · RESUELTO (2026-05-24):** branches
  `master` y `staging` comparten `G-NQPB4BHWMM` desde el fix del
  2026-05-08. Filtro de datos GA4 `Excluir tráfico de staging`
  (modificación de evento `marcar_staging_como_interno`: si
  `page_location contiene shiny_eph_panel_staging` → `traffic_type=internal`)
  **ACTIVADO** (pasó de modo Probando a Activo en validación panorámica 2026-05-24: capturaba 1 usuario / 11 eventos staging sobre 51 / 614 totales, ~2% contaminación sin falsos positivos).
  - Caveat: no aplica retroactivamente. Datos previos al 2026-05-18 siguen
    mezclados; para reportes históricos segmentar manual por
    `page_path no contiene _staging`.
  - **Load-bearing:** la URL del staging (`shiny_eph_panel_staging`). Si
    shinyapps.io cambia el slug, el filtro se rompe en silencio.

- **Botón `back_to_hub` duplicado (RESUELTO 2026-05-25):**
  Causa: section_topbar() con inputId FIJO repetido en 4 conditionalPanel (hub). Fix: inputId único por vista (back_to_hub_analisis, back_to_hub_metadata, etc.) + handler único observeEvent que escucha todos. Commit 3a7d8e2. INCLUIDO EN PR #80.

- **Backup local borrar (menor):** `data_raw/df_eph.parquet.bak` (40 MB, gitignored) generado durante re-bootstrap Aglomerado. **PENDIENTE borrar próxima sesión.**
- **Botón `back_to_hub` duplicado (RESUELTO 2026-05-25):** Implementación de inputId único por vista + handler único observeEvent que escucha todos. Commit 3a7d8e2. Incluido en PR #80. **CERRADO EN PROD 2026-05-28.**

## Comunicaciones y lanzamiento

| Material | Ubicación | Estado |
|---|---|---|
| Post 1° de mayo (Día del Trabajador) | `comunicaciones/2026-05-01_post_dia_trabajador.md` | Pendiente publicación |
| Post novedades mayo (v0.9.0 + descargas) | `comunicaciones/2026-05-04_post_novedades_mayo.md` | Pendiente publicación |
| **Post novedades (actualización ~24-may: modo interanual extendido + descarga panel + navegación rediseñada)** | `_gestion/sesiones/2026-05-24_post_novedades_shiny_eph_panel.md` | **Draft de LinkedIn listo para edición/publicación** · versiones Twitter/Telegram pospuestas |
| Posts rediseño hub-and-spoke (Twitter/LinkedIn/Telegram) | `comunicaciones/assets/2026-05-14_hub-and-spoke/posts.md` | Drafts listos con 6 screenshots, pendiente publicación |
| Cambios a comunicar (registro vivo) | `comunicaciones/cambios_a_comunicar.md` | Rediseño hub-and-spoke registrado |
| Artículo blog técnico (panel + EPH) | Web/Blog (pendiente) | En progreso |

## Próximos pasos sugeridos

- **Crear issue dedicado a11y Highcharts** (highcharter 0.9.5 · módulo carga después del binding). Opción A: upgrade highcharter, Opción B: inyectar el módulo antes del binding, Opción C: rearquitectura global cargando Highcharts en head.
- **Resto de #39** — auditoría `renv::status`, Lighthouse/axe sobre 4 secciones, chequeo de fonts (Fontshare + Google Fonts duplicadas).
- **Publicar post de novedades en LinkedIn/Twitter/Telegram** (drafts en `_gestion/sesiones/2026-05-24_post_novedades_shiny_eph_panel.md` y 2026-05-26, destaca descarga panel + modo interanual extendido + navegación rediseñada).
- **Monitorear feedback de usuarios sobre el rediseño UX en prod** (landing
  hub-and-spoke, sidebar interno, toggle Tipo de dúo).
- **Sprint E** · #29 (filtros sociodemográficos) y #30 (pobreza/
  indigencia). Desbloqueados tras el cierre efectivo de #12. Nota: #29
  comparte capa de filtros con el Armador (#77); si se hace, extraer
  módulo de filtros común.
- **Sprint D** · Decisión metodológica formal/informal (#13). Sesión
  enfocada cuando haya tiempo de revisar las 5 preguntas pendientes.
- Revisar GA4 después de ~1.5 meses de tracking productivo para guiar
  optimizaciones con datos reales.
- Cerrar issues #12, #44, #45, #46, #47, #48, #61 en GitHub
  (housekeeping).
- POC opcional de `{cookies}` (#75) cuando haya un rato libre.
