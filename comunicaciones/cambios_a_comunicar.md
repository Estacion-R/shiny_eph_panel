# Cambios a comunicar en redes

> Registro de cambios y mejoras del dashboard que ameritan post / contenido en
> redes sociales (Twitter, LinkedIn, Instagram, Telegram). Cada entrada queda
> "pendiente" hasta que se publique. Para redacción usar los lineamientos de
> `.claude/estilo-escritura-pablo.md` y delegar al agente `estacion-r-social-media`
> cuando corresponda.

## Formato de cada entrada

```
### [fecha-implementación] · Título corto
- **Estado:** pendiente | publicado (link)
- **Qué cambió:** descripción técnica corta.
- **Valor para el usuario:** por qué le importa al investigador / docente / alumno.
- **Ángulo de copy:** 1-2 ideas de gancho narrativo.
- **Asset visual:** screenshot, GIF, link a la pestaña relevante.
- **Audiencia prioritaria:** Twitter (ciencias sociales argentinas), LinkedIn
  (analistas de datos sector público), Telegram (alumnos Estación R).
- **Issue / commit:** referencia.
```

---

## Pendientes

### 2026-05-14 · Rediseño de navegación (hub-and-spoke)

- **Estado:** pendiente
- **Qué cambió:** el dashboard estrena pantalla de entrada. Reemplazamos el
  sidebar lateral por un Hub con 4 tarjetas grandes (Análisis de panel,
  Análisis transversal, Metadata, Datos). Al entrar a una sección aparece un
  sidebar interno con las sub-secciones (3 ejes + Calidad de la muestra).
  El toggle "Tipo de dúo" deja de ser un FAB flotante y pasa al pie del
  sidebar interno en formato compacto; un badge contextual arriba del
  contenido muestra siempre qué modo (Intertrimestral / Interanual) está
  activo. Las URLs ahora reflejan la vista activa (`?v=panel&s=cond_act`),
  permite share y bookmark.
- **Valor para el usuario:** menos fricción para encontrar qué hace cada
  análisis (el landing organiza por caso de uso, no por jerga metodológica),
  los filtros globales nunca se pierden con el scroll, y se puede compartir
  un link directo a una vista específica.
- **Ángulo de copy:**
  - "Reordenamos el dashboard pensando en cómo se usa, no en cómo está
    organizado el dato": pasamos de mostrar la metodología en la nav a
    organizarla por caso de uso.
  - Hub-and-spoke con filter rail sticky: detalle técnico para audiencia de
    devs / analistas que aprecian buen Shiny.
- **Asset visual:** screenshot del hub + GIF de navegación (Hub → sección →
  vuelta al hub). Comparación antes/después si rinde.
- **Audiencia prioritaria:** Twitter (ciencias sociales argentinas) +
  LinkedIn (devs de R/Shiny, analistas sector público).
- **Issue / commit:** issue #74 · branch `feat/hub-and-spoke-ux`.

---

## Publicados

### 2026-05-02 · Nueva sección "Datos" para descargar el panel longitudinal

- **Estado:** publicado en post combinado del 2026-05-04 (LinkedIn + Twitter).
  Ver `2026-05-04_post_novedades_mayo.md`.
- **Qué cambió:** se agregó una sección **Datos** en el sidebar del dashboard
  donde cualquiera puede bajar el panel longitudinal completo de la EPH ya
  armado, en Parquet o CSV (gzip). Suma también un diccionario de variables
  descargable y aviso metodológico (intervención INDEC, panel balanceado,
  inconsistencias, cobertura).
- **Valor para el usuario:** el panel longitudinal de la EPH no es trivial de
  armar (hay que parear personas entre trimestres con `eph::organize_panels()`
  y validar consistencia). Hasta ahora la app lo construía internamente pero
  no lo exponía. Ahora cualquier investigador, docente o alumno puede usarlo
  como insumo en sus análisis sin reproducir la lógica de pareo.
- **Ángulo de copy:**
  1. *"Si alguna vez quisiste analizar quién entra y sale del empleo formal en
     Argentina pero te frenaste al armar el panel, esto es para vos."*
  2. *"Sumamos descarga del panel longitudinal de la EPH. 1.86 M filas, 31
     columnas, 2003 a 2025."*
  3. Educativo: explicar qué es el esquema 2-2-2 y por qué hay que parear
     personas para análisis longitudinal (con link al dashboard).
- **Asset visual:** screenshot de la sección Datos (las 2 tarjetas con dropdown
  + botón). Capturado durante implementación, pendiente de versión definitiva.
- **Audiencia prioritaria:** Twitter (ciencias sociales argentinas, mercado de
  trabajo, analistas), LinkedIn (sector público, consultores). Para Telegram
  Estación R va más adelante con un tip vinculado.
- **Issue / commit:** issue #35.

### 2026-05-03 · Toggle "Tipo de dúo": análisis interanual (T año X vs T año X+1)

- **Estado:** publicado en post combinado del 2026-05-04 (LinkedIn + Twitter).
  Ver `2026-05-04_post_novedades_mayo.md`.
- **Qué cambió:** el FAB abajo a la derecha del dashboard ahora permite
  alternar entre análisis **intertrimestral** (T → T+1, default) y
  **interanual** (T año X → T año X+1, mismo trimestre). En modo
  interanual la **Foto** (matriz de transición + tasas + Sankey) se
  recalcula sobre el panel anual armado con `eph::organize_panels(window
  = "anual")`. Los selectores de año y dúo se adaptan automáticamente.
  Película y Tasas todavía muestran datos intertrim con un aviso visible
  (Fase 2/3 pendiente).
- **Valor para el usuario:** la EPH como panel permite seguir a las
  mismas personas entre años consecutivos (gracias al esquema 2-2-2), no
  solo entre trimestres adyacentes. Comparar T1-2024 con T1-2025
  **neutraliza la estacionalidad** y hace visibles cambios estructurales
  que el corte transversal anual no captura. Hasta ahora la app solo
  habilitaba el corte intertrim; ahora cubre la dimensión interanual,
  que es la lectura más usada en publicaciones académicas y reportes
  oficiales (cuando comparan trimestre con trimestre del año anterior).
- **Ángulo de copy:**
  1. *"Lo que pierde la foto trimestral, lo gana la película anual.
     Sumamos al dashboard EPH la opción de comparar el mismo trimestre
     entre años consecutivos sobre las mismas personas."*
  2. Educativo: estacionalidad vs cambio estructural, cómo el panel 2-2-2
     habilita ambos cortes, ejemplo concreto con tasa de informalidad.
  3. Casos de uso: *"si querés saber cuántos asalariados informales del
     T1-2024 siguen siendo informales en el T1-2025, esta es la vista".*
- **Asset visual:** screenshot del toggle abierto + Foto en modo
  interanual. Pendiente versión final con copy del trimestre seleccionado.
- **Audiencia prioritaria:** Twitter + LinkedIn (analistas datos,
  ciencias sociales, sector público). Telegram Estación R con un tip
  específico de cómo se construye el panel anual con `{eph}`.
- **Issue / commit:** issue #44 (Fase 1, Foto). Fase 2 + 3 pendientes.

### 2026-05-03 · Toggle "Tipo de dúo" se extiende a Película y Tasas

- **Estado:** publicado en post combinado del 2026-05-04 (LinkedIn + Twitter).
  Ver `2026-05-04_post_novedades_mayo.md`.
- **Qué cambió:** las pestañas **Película** (línea histórica) y
  **Tasas** (Persistencia / Salida / Entrada) ahora respetan el toggle
  Tipo de dúo. En modo Interanual muestran las series anuales reales,
  ya no el cartel "no soportado". Los selectores de trimestre se
  adaptan: `T1 / T2 / T3 / T4` en lugar de `1-2 / 2-3 / 3-4 / 4-1`.
  Cierra el feature end-to-end (queda Fase 3 con Calidad + descarga).
- **Valor para el usuario:** ahora el dashboard permite responder
  preguntas como "¿la tasa de informalidad del T1 entre 2003 y 2025
  cambió estructuralmente?" sin que el ruido estacional ensucie la
  serie. Es la lectura que todo informe oficial de mercado de trabajo
  hace al comparar trimestre con trimestre del año anterior, pero
  ahora sobre el panel longitudinal (mismas personas, no muestras
  independientes).
- **Ángulo de copy:**
  1. Continuación del post anterior: *"Lo prometido es deuda. Ahora
     el toggle Interanual actúa sobre toda la app: Foto, Película y
     Tasas."*
  2. Comparativo visual: GIF del mismo análisis (informalidad
     asalariada, por ejemplo) intertrim vs interanual, mostrando cómo
     desaparece la estacionalidad en la versión anual.
  3. Técnico-educativo: hilo corto sobre cómo se construye un panel
     anual con `eph::organize_panels(window = "anual")`, qué tipo de
     atrición tiene y por qué tiene mayor n por dúo de lo que parece.
- **Asset visual:** GIF o video corto del toggle aplicado en
  Película. Idealmente con la serie de tasa de Persistencia de
  Ocupados como ejemplo (es la métrica más simple y demostrativa).
- **Audiencia prioritaria:** misma que el post anterior (Twitter +
  LinkedIn). Considerar publicar como "follow-up" del primer post,
  no como pieza nueva.
- **Issue / commit:** issue #46 (Fase 2). v0.8.0.

### 2026-05-04 · Toggle Interanual end-to-end (Calidad + Datos)

- **Estado:** decidido **no postear standalone** (2026-05-10). Se integra en
  el tip técnico de R agendado para 11-14/5 (lectura del Parquet anual con
  `arrow::read_parquet()` + análisis de transición simple).
- **Decisión editorial (estacion-r-social-media, 2026-05-10):**
  1. El post del 4/5 ya agotó la promesa narrativa del feature ("interanual
     en Foto, Película y Tasas"). Calidad de la muestra y descarga del panel
     anual son cierre técnico, no capacidad nueva inesperada.
  2. Cadencia de 6 días sobre el mismo feature diluye el peso del post
     anterior y manda señal de "el primero estaba incompleto".
  3. Los cambios internos posteriores (149+ tests, CI, validación parquets,
     refactor anti-patterns) no tienen cara pública sin sonar a justificación.
  4. La mejora se comunica natural dentro del tip técnico ya agendado:
     foco educativo (cómo usar el archivo descargado), con mención de pasada
     al cierre del feature.
- **Qué cambió:** cierre del feature Tipo de dúo. El toggle ahora
  cubre **toda la app**: Foto, Película, Tasas, Calidad de la muestra
  y la sección Datos descargables. Calidad muestra el % de pareo y
  las inconsistencias para los dúos anuales con métrica adaptada
  (rango de edad `[CH06, CH06 + 2]` para reflejar el cumpleaños). En
  Datos hay una tarjeta nueva para bajar el panel anual (16 MB
  parquet · 18 MB CSV gzip).
- **Valor para el usuario:** quien quiera reproducir el análisis
  longitudinal con el corte interanual ahora tiene el dataset
  descargable + la métrica de calidad para reportar atrición y n
  efectivo del panel anual. Cierra la promesa del feature.
- **Issue / commit:** issue #47 (Fase 3). v0.9.0.
