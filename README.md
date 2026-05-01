# shiny_eph_panel

Dashboard interactivo del **mercado de trabajo argentino en clave de panel**, basado en la [Encuesta Permanente de Hogares (EPH) del INDEC](https://www.indec.gob.ar/indec/web/Institucional-Indec-SistemaEstadistico). Sigue a las mismas personas trimestre a trimestre y muestra cómo cambia su situación laboral en el tiempo.

🔗 **App productiva:** https://estacionr.shinyapps.io/shiny_eph_panel/
📦 **Repositorio:** https://github.com/Estacion-R/shiny_eph_panel

Hecho con R + Shiny por [Estación R](https://estacion-r.com/).

---

## Qué hace la app

Tres ejes de análisis longitudinal sobre el panel EPH (esquema de rotación 2-2-2):

- **Condición de actividad** · flujos entre Ocupados, Desocupados e Inactivos.
- **Categoría ocupacional** · movilidad entre Patrones, Cuenta propia, Asalariados y Trabajadores familiares.
- **Formal / Informal** · transiciones entre empleo formal e informal, definiciones clásica (asalariados, 2003+) y ampliada OIT 2023 (todos los ocupados, desde 2023-T4).

Para cada eje, la app muestra cuatro vistas:

| Tab | Qué hace |
|---|---|
| **Foto** | Sankey + matriz de transición + value boxes para un dúo trimestral puntual |
| **Comparar** | Dos Sankey lado a lado para comparar dos años distintos (sólo Cond. de actividad) |
| **Tasas** | Serie temporal de Persistencia / Salida / Entrada por categoría |
| **Película** | Línea histórica de un flujo específico (Desde X hacia Y) entre dúos |

Más una sección **Calidad de la muestra** que muestra el % efectivo del panel encontrado vs el tope teórico (50%) y el % de paneles con inconsistencias entre t0 y t1 (sexo distinto, edad imposible).

---

## Estructura del repo

```
shiny_eph_panel/
├── app.R                     # entry point Shiny (UI + server)
├── _brand.yml                # paleta y tipografía Estación R (sincronizado con identidad_visual)
├── init.R                    # paquetes a instalar en la VM antes del deploy (workflow GH Actions)
├── .rscignore                # qué archivos NO van al bundle de shinyapps.io
├── R/
│   ├── mod_analisis_cond_act.R     # módulo Foto/Comparar/Tasas/Película · cond. de actividad
│   ├── mod_analisis_cat_ocup.R     # idem · categoría ocupacional
│   ├── mod_analisis_formalidad.R   # idem · formal/informal (toggle clásica/ampliada)
│   ├── mod_calidad_panel.R         # módulo Calidad de la muestra
│   ├── utils_analisis.R            # helpers compartidos (matriz, tasas, Sankey, alertas)
│   └── panels_metadata.R           # paneles estáticos: Glosario, Definiciones
├── ETL/                      # scripts de pre-procesamiento (no corren en runtime)
│   ├── 00-libraries.R
│   ├── 01-extract.R                # carga de datasets pre-computados al iniciar la app
│   ├── 02-transform.R              # helpers UI (filter_query NLQ, factor periodo)
│   ├── 03-hc-theme.R               # tema Highcharts Estación R
│   ├── 03-update_data.R            # update mensual (vía workflow update_eph_data.yml)
│   ├── 05-build_panel_cat_ocup.R   # genera CSV histórico cat. ocupacional
│   ├── 06-build_panel_formalidad.R # genera CSV histórico formalidad clásica
│   ├── 07-build_panel_formalidad_ampliada.R
│   ├── 08-build_tasas_historico.R  # genera CSV de tasas P/S/E
│   ├── 09-build_paneles_runtime.R  # pre-computa panel_runtime.parquet
│   ├── 10-build_calidad_panel.R    # pre-computa calidad_panel_pct_historico.csv
│   └── 99-functions.R              # núcleo: armo_base_panel, preparo_base, etc.
├── data_raw/
│   └── df_eph.parquet              # microdato EPH-INDEC (excluido del bundle, usado solo por scripts ETL)
├── data_output/                    # datasets pre-computados que SÍ van al bundle
│   ├── panel_runtime.parquet       # panel armado para todos los dúos (clave para evitar OOM)
│   ├── panel_*_historico.csv       # paneles agregados para Sankey/línea
│   ├── tasas_*_historico.csv       # tasas P/S/E
│   ├── calidad_panel_pct_historico.csv
│   └── df_tasas_mt.parquet
├── www/                            # CSS, JS, logos servidos al cliente
├── documentacion_eph/              # corpus de fichas + PDFs INDEC (excluido del bundle)
├── .github/workflows/
│   ├── deploy_shinyapps.yml        # auto-deploy on-push a master
│   └── update_eph_data.yml         # cron mensual para detectar nuevos trimestres
└── ESTADO.md                       # estado operativo del proyecto (no del código)
```

---

## Stack técnico

| Componente | Qué usa |
|---|---|
| Frontend | `shiny` + `bslib` (theming · `_brand.yml`) + `bsicons` |
| Visualización | `highcharter` (Sankey, line, column) + `gt` (tablas de transición) |
| Datos | `arrow` (parquet, lazy Arrow Tables) + `dplyr` + `tidyr` |
| Dominio EPH | `eph` (organize_panels, ponderadores) |
| Deploy | `rsconnect` → shinyapps.io (R 4.5.3 pineado en el workflow) |
| CI/CD | GitHub Actions (`r-lib/actions/setup-r@v2`) |

Paleta y tipografía: ver [`_brand.yml`](_brand.yml). Sincronizado con [`identidad_visual`](https://github.com/Estacion-R/identidad_visual) de Estación R.

---

## Cómo correr la app local

Pre-requisitos: R ≥ 4.5 y los paquetes listados en [`init.R`](init.R).

```bash
# Clonar
git clone https://github.com/Estacion-R/shiny_eph_panel.git
cd shiny_eph_panel

# Instalar paquetes (corre todo init.R)
Rscript -e 'source("init.R")'

# Levantar la app
Rscript -e 'shiny::runApp(".", port = 3838, host = "127.0.0.1")'
```

La app necesita los datasets pre-computados en `data_output/`. Si no están (clone fresh), correr en orden:

```bash
Rscript ETL/05-build_panel_cat_ocup.R
Rscript ETL/06-build_panel_formalidad.R
Rscript ETL/07-build_panel_formalidad_ampliada.R
Rscript ETL/08-build_tasas_historico.R
Rscript ETL/09-build_paneles_runtime.R
Rscript ETL/10-build_calidad_panel.R
```

Los scripts ETL leen `data_raw/df_eph.parquet` (microdato EPH). Si no lo tenés, hay que correr el extract de los aglomerados desde el paquete `eph` o pedírselo a Pablo.

---

## Por qué un `panel_runtime.parquet` pre-computado

El microdato completo de la EPH (740k filas × 15 columnas) pesa ~570 MB en RAM cuando se carga como tibble en R, lo que rompe el límite del plan free de shinyapps.io (~1 GB por instancia, OOM). Para evitarlo:

1. `ETL/09-build_paneles_runtime.R` itera todos los dúos válidos (~83 dúos para serie 2003-2025-T4), arma cada panel con `armo_base_panel()` + `eph::organize_panels()`, agrega columnas `(anio_0, trim_0)` como key y guarda todo en un único parquet (`panel_runtime.parquet`, ~21 MB en disco).
2. La app levanta ese parquet como **Arrow Table lazy** y `armo_base_panel()` solo filtra por `(anio_0, trim_0)` → `collect()`. Footprint mínimo en runtime, mismos resultados que el cómputo on-the-fly.
3. El microdato `data_raw/df_eph.parquet` queda excluido del bundle vía `.rscignore` (no se sube a shinyapps.io).

Esto es **patrón obligatorio** para cualquier feature nueva que toque el microdato: pre-procesar a parquet/CSV en `data_output/`, runtime solo lee.

---

## Pipeline automático

| Componente | Cuándo | Qué hace |
|---|---|---|
| `update_eph_data.yml` | Día 5 cada mes, 12 UTC | Chequea si hay un trimestre nuevo en INDEC; si lo hay, descarga, regenera todos los datasets pre-computados, abre PR auto-merge a master |
| `deploy_shinyapps.yml` | On-push a master con paths relevantes | Bundlea + deploya con `rsconnect::deployApp()` (account `estacionr`, R 4.5.3) |
| Audit routine remota | Día 7 cada mes, 14 ART | Audita el ciclo del mes y reporta a Pablo |

Si actualizás el microdato manualmente (sin esperar al cron), correr en orden los scripts ETL antes de pushear (ver sección "Cómo correr la app local").

---

## Documentación adicional

- **Glosario y Definiciones** dentro de la app (`Metadata`) · variables EPH usadas + conceptos metodológicos del panel longitudinal (esquema 2-2-2, dúo, persistencia/salida/entrada, intervención INDEC 2007-2015, definiciones de informalidad, limitaciones del panel y nota sobre significancia estadística).
- **Anexo INDEC 2016** sobre el período de intervención: [PDF oficial](https://www.indec.gob.ar/ftp/cuadros/sociedad/anexo_informe_eph_23_08_16.pdf).
- **Documento metodológico EPH continua**: [PDF INDEC](https://www.indec.gob.ar/ftp/cuadros/sociedad/metodologia_eph_continua.pdf).
- **Paquete `eph`** de rOpenSci: https://docs.ropensci.org/eph/.
- Estado operativo del proyecto: [`ESTADO.md`](ESTADO.md).

---

## Issues abiertos relevantes

- **#35** · Sección de descarga del dataset con paneles armados (idea, no priorizado).
- **#37** · Decidir si excluir paneles inconsistentes del cálculo de tasas en los 3 mods (parcial: ya se mide y se muestra el % de inconsistencias en Calidad de la muestra).

---

## Licencia y créditos

Datos: **EPH-INDEC**, base de datos abierta del Instituto Nacional de Estadística y Censos de la República Argentina.

App: **Estación R** · Pablo Tiscornia · pablotiscornia@estacion-r.com

Reportar issues, sugerencias o errores: https://github.com/Estacion-R/shiny_eph_panel/issues
