# Diseño · Armador de panel

> Documento de diseño del épico "Armador de panel personalizado".
> Estado: **diseño cerrado, pendiente de implementación**.
> Creado: 2026-05-18. Decisiones tomadas con Pablo en sesión del 2026-05-18.
> Issues: **#77** (épico MVP) · **#78** (Aglomerado fast-follow).

---

## Objetivo

Nueva tarjeta en el landing hub que lleva a una sección donde el usuario
**arma su propio panel** aplicando cortes al dataset longitudinal ya
procesado (sin tener que limpiar datos) y lo **descarga** para sus propios
análisis, más allá de los que ofrece la app.

**Reemplaza la sección actual "Datos descargables"** (`R/panel_descarga.R`)
para no duplicar funcionalidad: el Armador es la sección de descarga, ahora
con filtros.

---

## Qué NO es (deslinde de #29)

El Armador comparte la *capa de filtros* con el issue **#29 (filtros
sociodemográficos)** pero el destino del filtro es distinto:

| | #29 | Armador |
|---|---|---|
| Filtros alimentan | gráficos (Foto/Película/Tasas) | dataset descargable |
| Output | visualización recalculada | archivo (parquet/CSV) |
| Estado | OPEN, Sprint E | este documento |

Son **features hermanas**, no la misma. Si en el futuro se hace #29,
conviene extraer el panel de filtros como módulo reutilizable compartido.

---

## Decisiones cerradas (2026-05-18)

1. **Scope de Pobreza: diferido a v2.** El MVP arranca con 5 filtros. Pobreza
   requiere construir el cálculo completo (ITF + canastas CBA/CBT por
   aglomerado + adultos equivalentes), que es el issue **#30**. Se suma al
   Armador recién cuando #30 esté hecho.
2. **Filtro t0/t1: elegible por el usuario.** Para los filtros de variables
   que cambian entre olas (Condición de actividad, Categoría ocupacional), el
   usuario elige si el filtro aplica al estado en **t0** o en **t1**. Sexo y
   edad son estables: se filtran sobre t0 sin ofrecer la distinción.
3. **Preview antes de descargar: conteo + tabla.** Mostrar "N personas / N
   filas en tu panel" + tabla con las primeras ~20 filas (DT). El usuario ve
   qué se lleva antes de bajar el archivo.
4. **Toggle t0/t1: global** (un solo control para toda la sección, no por
   filtro). Aplica a las variables que cambian entre olas (Condición de
   actividad, Categoría ocupacional).
5. **MVP con 4 filtros.** Aglomerado sale como fast-follow (issue aparte) porque
   requiere re-descargar el microdato. El Armador no espera esa descarga.
6. **Aglomerado: individual** cuando llegue. Región (agrupación) es issue
   posterior.

---

## Variables del MVP

| Filtro | Variable(s) | Disponibilidad | En MVP |
|---|---|---|---|
| Sexo | `CH04` | ✅ ya en panel runtime | ✅ sí |
| Edad | `CH06` (+ `CH06_t1`) | ✅ ya en panel runtime | ✅ sí |
| Condición de actividad | `ESTADO` / `ESTADO_t1` | ✅ ya en panel runtime | ✅ sí |
| Categoría ocupacional | `CAT_OCUP` / `CAT_OCUP_t1` | ✅ ya en panel runtime | ✅ sí |
| Aglomerado | `AGLOMERADO` | ❌ ni en panel ni en microdato | **fast-follow** (issue aparte) |
| ~~Pobreza~~ | calculada | ❌ es #30 | **v2** |

El panel runtime hoy tiene **31 columnas** (ver diccionario en
`R/panel_descarga.R:15`). El MVP usa 4 filtros que ya están · no requiere
tocar el ETL.

### Por qué Aglomerado es fast-follow y no MVP (hallazgo 2026-05-18)

El microdato local (`data_raw/df_eph.parquet`) fue **reducido a 15 columnas**
(`vars_eph` en `03-update_data.R:42`) y **no incluye `AGLOMERADO`**. Sumarlo no
es tocar `variables_runtime`: hay que re-descargar los **86 trimestres** de EPH
desde INDEC (2003-T3 → 2025, 4.65 M filas) con `eph::get_microdata()` agregando
`AGLOMERADO` a `vars_eph`. Es un bootstrap completo (el script 03 es
incremental), dependiente del servidor INDEC, de 30 min a varias horas. Se hace
en un issue dedicado, desacoplado del lanzamiento del Armador.

Pasos del fast-follow (issue Aglomerado):
1. Backup del microdato actual (`.bak`).
2. Agregar `"AGLOMERADO"` a `vars_eph` (`03-update_data.R:42`).
3. Re-bootstrap: re-bajar los 86 trimestres con la columna nueva.
4. Agregar `"AGLOMERADO"` a `variables_runtime` (scripts `09` y `09b`).
5. Regenerar parquets runtime intertrim + anual.
6. Actualizar diccionario (31→32 cols) + validación (`12-validate...`).
7. Enchufar el filtro Aglomerado (individual) en el módulo del Armador.
8. **Región** (NEA/NOA/Cuyo/Pampeana/Patagonia/GBA/CABA): issue separado posterior.

---

## Arquitectura técnica

### Filtrado server-side con Arrow lazy (no cargar todo en RAM)

El panel intertrim tiene **1.86 M filas** y el anual **1.41 M**. La app ya
resolvió un OOM histórico cargando solo el parquet pre-computado. El Armador
debe respetar ese principio:

```r
# Patrón: abrir lazy, filtrar lazy, materializar solo lo necesario
ds <- arrow::read_parquet(ruta_parquet, as_data_frame = FALSE)  # Arrow Table

filtrado <- ds |>
  dplyr::filter(<condiciones reactivas>)   # lazy, no ejecuta todavía

n_filas    <- filtrado |> nrow()                       # barato
preview_df <- filtrado |> head(20) |> dplyr::collect()  # solo 20 filas
# collect() completo SOLO dentro del downloadHandler
```

- **Conteo** (`nrow`) y **preview** (`head(20)`) son baratos sobre Arrow.
- **`collect()` completo** se ejecuta únicamente al apretar Descargar.
- Caso "sin filtros" = panel completo → equivale a la descarga actual (ya
  funciona, no regresiona).

### Construcción de las condiciones de filtro

- Filtros multi-select aditivos (AND entre variables, OR dentro de cada una).
- Para `ESTADO`/`CAT_OCUP`: el toggle t0/t1 elige sobre qué columna se filtra
  (`ESTADO` vs `ESTADO_t1`). Implementar con `.data[[col]]` (acceso
  programático, nunca `eval(parse())`).
- Edad: range slider (`CH06` 14–99) sobre t0.
- Aglomerado: multi-select con etiquetas legibles (tabla código→nombre) +
  opción de agrupar por región (NEA/NOA/Cuyo/Pampeana/Patagonia/GBA/CABA),
  alineado con la agrupación que propone #29.

---

## UX / flujo

```
Landing hub
  └── Tarjeta "Armá tu panel"
        └── Sección Armador
              ├── [1] Selector dataset: Intertrimestral | Interanual
              ├── [2] Toggle GLOBAL momento del dúo: t0 | t1
              ├── [3] Panel de filtros (sidebar o accordion)
              │     ├── Sexo            (multi-select)
              │     ├── Edad            (range slider, t0)
              │     ├── Cond. actividad (multi-select, usa el toggle global)
              │     ├── Cat. ocupacional(multi-select, usa el toggle global)
              │     └── [fast-follow] Aglomerado (multi-select)
              ├── [4] Indicador: "N personas · N filas en tu panel"
              │       (con warning si el subconjunto es muy chico)
              ├── [5] Preview: tabla DT con primeras ~20 filas
              └── [6] Descargar: Parquet | CSV (gzip)
```

### Qué preservar de la sección Datos actual

El Armador reemplaza a `panel_descarga.R` pero debe conservar:

- [x] Selector intertrim / anual (son dos datasets distintos).
- [x] Caso "sin filtros = panel completo".
- [x] Formatos Parquet + CSV gzip.
- [x] Diccionario de variables descargable (actualizado a 32 cols con
      `AGLOMERADO`).
- [x] Aviso de limitaciones metodológicas (intervención INDEC, panel
      balanceado, inconsistencias, cobertura).
- [x] Tracking GA4 `dataset_download` (sumar dimensión de filtros aplicados
      si es barato).

---

## Plan de implementación por fases

### MVP (4 filtros · sin tocar ETL)

| Fase | Qué | Esfuerzo |
|---|---|---|
| **F1 · Módulo filtros** | `R/mod_armador.R`: UI de 4 filtros + toggle global t0/t1 + lógica reactiva de filtrado server-side Arrow lazy. Acceso programático a columnas con `.data[[]]` | ~3-4 hs |
| **F2 · Preview + descarga** | Conteo reactivo, preview DT, `downloadHandler` con `collect()` filtrado (parquet + CSV gzip), warning de N chico | ~2-3 hs |
| **F3 · Integración hub** | Nueva tarjeta en landing (`R/panel_hub.R`), routing a la sección, retirar/redirigir la tarjeta "Datos descargables" | ~1-2 hs |
| **F4 · Tests** | testthat para la lógica de filtrado (funciones puras), shinytest2 para el flujo elegir filtros → conteo → descarga | ~2-3 hs |
| **F5 · Deploy** | staging → validar (incluye chequear que GA4 staging no contamina, filtro recién creado) → prod | ~1 hs |

**Total estimado MVP:** ~9-13 hs. Se puede partir en 2-3 micro-sprints.

### Fast-follow · Aglomerado (issue aparte)

Re-descarga del microdato con `AGLOMERADO` + regeneración de parquets + enchufar
el filtro. Ver pasos en la sección "Por qué Aglomerado es fast-follow". No
bloquea el MVP. ~3-5 hs + tiempo de descarga INDEC.

### v2 · Pobreza

Atada al issue **#30**. Requiere construir el cálculo (ITF + canastas + adultos
equivalentes) antes de exponerla como filtro.

---

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Performance al filtrar 1.86 M filas en shinyapps.io | Arrow lazy: `nrow`/`head` baratos, `collect()` solo al descargar |
| OOM si el usuario descarga sin filtrar | Es el caso actual, ya funciona. El filtrado solo reduce el volumen |
| Confusión con el toggle t0/t1 | Copy claro ("¿en qué momento del dúo?") + default t0 |
| Aglomerado: códigos numéricos crípticos | Tabla código→nombre + opción de agrupar por región |
| Combinaciones con n muestral bajo | Warning visible "<100 dúos: muestra chica, leé con cautela" (criterio de #29) |
| Romper descargas actuales al reemplazar la sección | Preservar caso "sin filtros" + tests E2E del flujo de descarga |

---

## Preguntas resueltas y abiertas

**Resueltas (2026-05-18):**
- Toggle t0/t1: **global**.
- Aglomerado: **individual** (región es issue posterior), y va como **fast-follow**.
- Pobreza: **v2** (atada a #30).
- Preview: **conteo + tabla DT** de ~20 filas.

**Abiertas (resolver durante implementación):**
- ¿La descarga filtrada conserva todas las columnas o el usuario elige cuáles?
  (MVP: todas las columnas; selección de columnas es mejora futura).
- ¿Sidebar o accordion para el panel de filtros? (decidir al maquetar, alinear
  con el patrón hub-and-spoke existente en `R/panel_seccion.R`).

---

## Relación con el roadmap

- **Pre-requisito #12** (refactor `mod_analisis()`): ✅ ya cerrado (2026-05-11).
- Este épico es independiente de #29 y #30 pero comparte la capa de filtros con
  #29. Si se hace #29 después, extraer módulo de filtros común.
- Pobreza (v2 del Armador) queda atada a **#30**.
