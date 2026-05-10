# Roadmap — shiny_eph_panel

> Plan de prioridades vivo. Se actualiza al cerrar cada sprint.
> Última revisión: **2026-05-09**.

---

## Versión actual

**v0.9.0** en master + producción. Cierra Sprint A (#44 Tipo de dúo
end-to-end). Sobre esa base se agregaron, sin bumpear versión por ser
trabajo interno: Sprint Testing (3 capas, 192 tests) y Sprint B
(#45 validación ETL como gate + #39 barrido de anti-patterns
dplyr/purrr). Detalle en [CHANGELOG.md](CHANGELOG.md).

---

## Sprints completados

### Sprint A · Tipo de dúo end-to-end (#44) · cerrado 2026-05-04

Toggle Interanual habilitado en toda la app: Foto, Película, Tasas,
Calidad de la muestra y descargas en sección Datos.

- [x] **#48** Pipeline mensual auto-regenera parquets runtime.
- [x] **#46** Fase 2: Película + Tasas en modo Interanual.
- [x] **#47** Fase 3: Calidad + Datos descargables en modo Interanual.

Shipped en v0.9.0 (PR #60).

### Sprint Testing · Cobertura automatizada (#61) · cerrado 2026-05-07

Pirámide de tests en 3 capas: 185 unit + 7 E2E = 192 tests. Stack:
`testthat 3.x` + `shiny::testServer()` + `shinytest2`.

- [x] **test-1** · Funciones puras (149 tests). Cubre
      `agrega_vars_derivadas`, `armo_tabla_sankey`,
      `duos_disponibles_por_anio`, `duo_label`, `arma_tasas_destacadas`,
      `regenerar_panel_historico`, `arma_matriz_transicion`,
      `build_tasas_historico`, `regenerar_calidad_panel`,
      `formato_delta`, `sankey_label_legible`, `sankey_nodes_orden`.
- [x] **test-2** · Server logic con `testServer()` (+36 tests).
      `mod_calidad_panel_server` (reactives + KPIs con stub de
      `renderHighchart`) y `armo_base_panel(window="anual")` con
      parquet fixture sintético (filter pushdown, drop de cols
      anio_0/trim_0, errores).
- [x] **test-3 lite** · E2E con `shinytest2` (+7 expects). Smoke,
      toggle tipo_duo (trim ↔ anual), render de KPI tras navegar a
      Calidad.
- [x] CI: workflow `tests-unit.yml` corre en cada PR;
      `tests-e2e.yml` corre vía `workflow_dispatch` + cron semanal
      (no en cada PR para no inflar el ciclo).
- [x] Guard `RUN_E2E=true` para que dev local no arrastre Chromote.

**Diferido a futuros sprints:**
- `mod_analisis_*_server` (los 3 mods): mock de globales complejo,
  más rentable cubrir con E2E si aparece la necesidad.
- E2E de descarga (Chromote tiene quirks con `downloadHandler` +
  `file.copy`).
- Codecov action (no justifica el costo hoy).
- Snapshot testing de los charts Foto / Película (regresión #40),
  hoy frágil.

**Pitfall confirmado:** `testServer()` NO refleja
`updateSelectInput()` en `session$input`. Tests del toggle Tipo de
dúo solo confiables con `shinytest2` AppDriver.

### Sprint B · Calidad técnica · cerrado 2026-05-09

- [x] **#45** Validación ETL paneles intertrim + anual.
      Script `ETL/12-validate_paneles_runtime.R` con 29 tests
      testthat: schema (31 cols + tipos), cobertura (≥75 dúos trim,
      ≥65 anual, empieza 2003-T3), tamaño/atrición (n>5000 por dúo,
      ratio anual/trim ∈ [40%, 120%]), cross-val tasas CSV vs parquet
      (tolerancia 0.5 pp). Integrado a `update_eph_data.yml` como
      gate post 09b: si falla, el workflow aborta y prod no recibe
      datos corruptos.
- [x] **#39** Barrido de anti-patterns (scope acotado).
      10 ocurrencias `pmap_dfr` / `map_dfr` → `pmap()/map() |> list_rbind()`,
      2 `group_by + ungroup` → `.by`, 3 `%>%` magrittr → `|>` nativo.
      Refactor sin cambio funcional: los 185 tests siguen verde.

**Diferido a otro sprint:** CSS muerto, perf con profvis,
accesibilidad, dependencias no usadas.

---

## Sprint C · Refactor habilitante

**Objetivo:** abaratar las features mayores que vienen.

- **#12** Refactor a `mod_analisis()` genérico · ~3-4 hs.
  Los 3 módulos (cond_act, cat_ocup, formalidad) comparten ~80% del
  código. Después del refactor, sumar un 4° módulo (pobreza, #30) o
  filtros sociodemográficos (#29) requiere modificar 1 lugar en
  lugar de 3.

**Cuándo:** antes de #29 y #30 sí o sí.

---

## Sprint D · Decisión metodológica

- **#13** Formal/Informal "tiene descuento jubilatorio" · ~1-2 hs.
  Bloqueado por 5 preguntas metodológicas que requieren input de
  Pablo (universo, no-asalariados, NA, caption, regen histórico).

**Cuándo:** una sesión enfocada cuando Pablo tenga tiempo de revisar
las preguntas. No es bloqueante para nada más.

---

## Sprint E · Features mayores (sprints dedicados)

### #29 Filtros sociodemográficos · ~4-6 hs

Sumar filtros por sexo, grupo etario, nivel educativo, jefatura de
hogar, presencia de menores, aglomerado/región a las matrices y
tasas. Habilita preguntas como *"¿quién persiste en la informalidad?"*.

**Pre-requisito:** #12 (refactor) para que el cambio sea uno solo.

### #30 Pobreza/indigencia · ~8-12 hs

Cuarto módulo: transiciones de pobreza e indigencia entre dos puntos
del panel. Dataset propio (canastas CBA/CBT mensuales por aglomerado,
deflactor IPC). Diferencial fuerte vs reportes oficiales de INDEC.

**Pre-requisito:** #12 (refactor). Sprint dedicado.

---

## Backlog wishlist

| # | Notas |
|---|---|
| **#5** Chatbot ellmer + Gemini | Spike exploratorio. Cuando haya energía y costo justificable |
| **#42** Migrar Glosario/Definiciones a `.md`/`.qmd` | Mejora de mantenibilidad. Solo cuando crezca el contenido |
| **#43** Extender glosario con variables nuevas | Convención: aplicar al cerrar cada feature con vars nuevas (#29, #30) |

---

## Cómo se mantiene este documento

- Al cerrar un sprint, mover sus issues a `## Sprints completados`
  con la fecha de cierre y el PR/versión donde shippeó.
- Al re-priorizar, actualizar el orden y agregar nota de cuándo y
  por qué.
- Si entra un issue urgente fuera de plan (bug crítico, requerimiento
  externo), evaluar si interrumpe Sprint actual o se difiere.
