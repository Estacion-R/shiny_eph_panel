# Estado · shiny_eph_panel

> Última actualización: 2026-05-01

## Live

- **App productiva:** https://estacionr.shinyapps.io/shiny_eph_panel/
- **Repo:** https://github.com/Estacion-R/shiny_eph_panel
- **Datos hasta:** 2025-T4 (próxima publicación INDEC esperada agosto/septiembre 2026)

## Secciones de la app

| Sección | Estado |
|---|---|
| Inicio (landing) | OK |
| Análisis de panel · Condición de actividad | OK |
| Análisis de panel · Categoría ocupacional | OK |
| Análisis de panel · Formal / Informal (clásica + ampliada) | OK |
| Análisis de panel · **Calidad de la muestra** | OK (nuevo, 2026-05-01, issue #36) |
| Análisis transversal · Indicadores básicos | Próximamente (placeholder) |
| Análisis transversal · Calidad del empleo | Próximamente (placeholder) |
| Metadata · Glosario + Definiciones + links | OK |

## Pipeline automático

| Componente | Cuándo | Hace |
|---|---|---|
| `update_eph_data.yml` | Día 5 cada mes, 12 UTC | Detecta nuevos trimestres → PR auto-merge → deploy |
| `deploy_shinyapps.yml` | On-push a master con paths relevantes | Deploy directo |
| Routine `trig_01Y3TmHxhCjecnGg8qRmNFac` | Día 7 cada mes, 14 ART | Audita el ciclo y reporta |

## Datos pre-procesados (cargados al iniciar la app)

| CSV / Parquet | Filas | Generado por |
|---|---|---|
| `data_output/panel_runtime.parquet` | ~varios MB | `ETL/09-build_paneles_runtime.R` |
| `data_output/panel_cond_act_historico.csv` | ~80 paneles × 9 categorías | `03-update_data.R` (cron) |
| `data_output/panel_cat_ocup_historico.csv` | ídem | `03-update_data.R` |
| `data_output/panel_formalidad_historico.csv` | ídem | `03-update_data.R` |
| `data_output/panel_formalidad_ampliada_historico.csv` | desde 2023-T4 | `03-update_data.R` |
| `data_output/tasas_*_historico.csv` × 4 | tasas Persistencia/Salida/Entrada | `08-build_tasas_historico.R` |
| `data_output/calidad_panel_pct_historico.csv` | 83 dúos | `10-build_calidad_panel.R` + cron |
| `data_output/df_tasas_mt.parquet` | tasas mercado de trabajo | `03-update_data.R` |

## Issues abiertos

- **#35** — Sección de descarga del dataset con paneles (idea, no priorizado).
- **#37** — Decisión sobre si excluir paneles inconsistentes del cálculo de tasas en los 3 mods analíticos (parcial: ya se mide y se muestra el % en Calidad de la muestra; falta la decisión de aplicarlo o no a los cálculos).

## Issues cerrados recientemente

- **#37** — Calidad: % de paneles encontrados con inconsistencias entre t0 y t1 (2026-05-01) — total (flag eph) + sexo distinto + edad imposible. 4 KPIs nuevas + chart histórico en el panel Calidad de la muestra. Datos: ~5.9% de inconsistencia total mediana, 10.8% por edad, 1.6% por sexo.
- **#36** — Calidad: histórico de % personas-panel encontradas (2026-05-01) — implementado con eje 0-50% en lugar de stack 100% (más correcto conceptualmente: el complemento es diseño muestral, no atrición).

## Pendientes técnicos menores

- Comentario obsoleto en `ETL/09-build_paneles_runtime.R:24` dice "carga df_eph_full" pero el `01-extract.R` actual ya no lo carga (el script 09 hace su propio `arrow::read_parquet`). No bloquea, solo confunde.
- `ETL/10-build_calidad_panel.R` no está en `.rscignore`. Va al bundle pero no se ejecuta en runtime; consistente con 05-09 que tampoco están excluidos. Costo despreciable.

## Comunicaciones y lanzamiento

| Material | Ubicación | Estado |
|---|---|---|
| **Post 1° de mayo** (Día del Trabajador) | `comunicaciones/2026-05-01_post_dia_trabajador.md` | ✅ Cerrado (pendiente publicación LinkedIn 2026-05-01) |
| **Artículo blog técnico** (panel + EPH) | Web/Blog (pendiente) | 🔴 En progreso (deadline 2026-05-02, falta dato merma panel) |

## Sesión 2026-05-01 (resumen)

Hitos cerrados durante la sesión:

- **UX overhaul pre-launch**: lotes 1-4 (logo Estación R · alert removido · footer · landing rediseñado · jerarquía value boxes · matriz con etiquetas legibles · typos · microcopia).
- **Reorganización del sidebar**: "Sobre la app" → "Inicio" como landing; +Info absorbido por Metadata; "Análisis transversal" agregado como menú placeholder.
- **Sección Definiciones expandida** según anexo INDEC 2016 sobre intervención + nota propia sobre significancia estadística (no hay metodología oficial INDEC para errores estándar de panel).
- **Tarjeta "Población" como primera** de las 4 en Foto · orden estable de categorías en Sankey via `sankey_nodes_orden()` · tabs migradas a `navset_card_underline`.
- **Fix OOM en producción**: pre-cómputo de paneles armados en `panel_runtime.parquet` (~21 MB) reemplaza la carga del microdato (~570 MB en RAM). `armo_base_panel()` refactorizado con modos runtime / legacy. Resuelve definitivamente el OOM en plan free de shinyapps.io.
- **Issue #37**: panel Calidad ahora mide % de paneles con inconsistencias entre t0 y t1 (total / sexo / edad) + 3 nuevas value boxes y chart histórico.

**Pendiente apertura próxima sesión:**

- Decidir tratamiento de paneles inconsistentes en el cálculo de tasas (issue #37, parcial).
- Cleanup técnico menor: comentario obsoleto en `ETL/09-build_paneles_runtime.R:24` y `ETL/10-build_calidad_panel.R` no listado en `.rscignore`.
- Revisión visual completa de los 3 mods en producción con los 4 KPI reordenados + Sankey con orden estable + tabs underline.
