# Roadmap — shiny_eph_panel

> Plan de prioridades vivo. Se actualiza al cerrar cada sprint.
> Última revisión: **2026-05-04**.

---

## Versión actual

**v0.8.1** en master/staging. PR #60 pendiente con v0.9.0 (cierre
Sprint A). Ver [CHANGELOG.md](CHANGELOG.md) para el detalle.

---

## Sprint Testing · Sumar capa de tests automatizados (#61)

**Objetivo:** sumar tests en 3 capas. Stack confirmado por research:
`testthat 3.x` + `shiny::testServer()` + `shinytest2`.

### Sprint test-1 · Funciones puras (~4-6 hs)

- [x] Setup `tests/testthat/` + runner + helper-fixtures
- [x] Fixture sintética `panel_mock.rds` (100 individuos × 3 ondas)
- [x] Tests: `agrega_vars_derivadas`, `armo_tabla_sankey`,
      `duos_disponibles_por_anio`, `duo_label` → **42 tests PASS**
- [ ] Tests pendientes: `arma_tasas_destacadas`,
      `regenerar_panel_historico`, `armo_base_panel` modo legacy
- [ ] CI: GitHub Actions `tests-unit.yml`

### Sprint test-2 · Server logic con testServer() (~3-4 hs)

- [ ] Tests `mod_calidad_panel_server`, `mod_analisis_*_server`
      (reactives, NO `update*()`)
- [ ] Test de `armo_base_panel(window = "anual")` con `open_dataset`

### Sprint test-3 · E2E con shinytest2 (~4-5 hs)

- [ ] 5-7 tests E2E: toggle Tipo de dúo, descargas, regresión #40
- [ ] CI: workflow `tests-e2e.yml` solo en PR a master
- [ ] Codecov action

**Pitfall confirmado por research:** `testServer()` NO refleja
`updateSelectInput()` en `session$input`. Tests del toggle Tipo de dúo
solo confiables con `shinytest2` AppDriver.

---

## Sprint A · Cerrar feature Tipo de dúo (#44 completo)

**Objetivo:** terminar de habilitar el toggle Interanual en toda la
app. Hoy solo Foto soporta Interanual; Película y Tasas muestran un
banner azul "no soportado".

**Orden:**

1. **#48** Pipeline mensual auto-regenera parquets runtime · ~1 hr.
   Sin esto, cada update mensual deja CSVs nuevos y parquets viejos.
2. **#46** Fase 2: Película + Tasas en modo Interanual · ~2-3 hs.
   Genera CSVs anuales pre-calculados, conecta los módulos, quita
   el banner.
3. **#47** Fase 3: Calidad + Datos descargables en modo Interanual ·
   ~1-2 hs. Cierra el feature visual end-to-end.

**Por qué este orden:** #48 antes de #46 porque automatizar la
regeneración del panel anual es prerequisito para que los CSVs
anuales no entren en drift cuando se cargue un trimestre nuevo.

---

## Sprint B · Calidad técnica

**Objetivo:** robustez y limpieza después de meter Tipo de dúo
completo.

- **#45** Validación ETL paneles intertrim + anual · ~2 hs.
  Schema, cobertura, tamaño, distribuciones, consistencia.
- **#39** Pasada integral (parcial) · ~3-5 hs.
  Anti-patterns dplyr/purrr, CSS muerto, dependencias no usadas.
  Diferimos lo grande (refactor mayor) que se cubre en Sprint C.

**Cuándo:** después de Sprint A. Ya tendremos ~1.5 meses de GA4
acumulado para guiar optimizaciones con datos reales.

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

- Al cerrar un sprint, mover los issues completados a la sección
  `## Sprints completados` (a crear cuando suceda) con el rango de
  fechas.
- Al re-priorizar, actualizar el orden y agregar nota de cuándo y
  por qué.
- Si entra un issue urgente fuera de plan (bug crítico, requerimiento
  externo), evaluar si interrumpe Sprint actual o se difiere.
